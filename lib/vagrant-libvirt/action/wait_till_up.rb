require 'log4r'
require 'vagrant-libvirt/util/timer'
require 'vagrant/util/retryable'
require 'vagrant/util/network_ip'
require 'vagrant/util/scoped_hash_override'
require 'net/telnet'


module VagrantPlugins
  module ProviderLibvirt
    module Action

      # Wait till domain is started, till it obtains an IP address and is
      # accessible via ssh.
      class WaitTillUp
        include Vagrant::Util::Retryable
        include Vagrant::Util::NetworkIP
        include VagrantPlugins::ProviderLibvirt::Util::NetworkUtil
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant_libvirt::action::wait_till_up")
          @app = app
        end

        def call(env)
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          # Get domain object
          domain = env[:libvirt_compute].servers.get(env[:machine].id.to_s)
          raise NoDomainError if domain == nil

          # Wait for domain to obtain an ip address. Ip address is searched
          # from arp table, either localy or remotely via ssh, if libvirt
          # connection was done via ssh.
          env[:ip_address] = nil
          env[:metrics]["instance_ip_time"] = Util::Timer.time do
            env[:ui].info(I18n.t("vagrant_libvirt.waiting_for_ip"))
            retryable(:on => Fog::Errors::TimeoutError, :tries => 300) do
              # If we're interrupted don't worry about waiting
              next if env[:interrupted]
              #next if configured_networks(env, @logger).count == 1

              # Wait for domain to obtain an ip address
              if env[:machine].provider_config.management_network == false &&
                configured_networks(env, @logger).select {|net| net[:iface_type] == :public_network}.first[:ip] != nil

 		firstnet = configured_networks(env, @logger).select {|net| net[:iface_type] == :public_network}.first
                env[:ui].info(I18n.t("vagrant_libvirt.wait_for_ip_configuration_telnet"))
                interfaceconfig = {:name => "vio0", :ip => firstnet[:ip]}
                localhost = Net::Telnet::new("Host" => "localhost",
                             "Port" => env[:machine].provider_config.serial_port,
                             "Timeout" => false,
                             "Prompt" => /[$%#>] /n)
                localhost.login("vagrant", "vagrant") { |c| print c }
                sleep 2
                localhost.cmd("String" => "sudo ifconfig #{interfaceconfig[:name]} #{interfaceconfig[:ip]}") { |c| print c }
                sleep 2
                localhost.close
                env[:ip_address] = interfaceconfig[:ip]
                env[:ui].info(I18n.t("vagrant_libvirt.need_to_configure_ip_yourself"))
                next
              elsif  env[:machine].provider_config.management_network == false &&
                configured_networks(env, @logger).select {|net| net[:iface_type] == :public_network}.first[:ip] == nil

                env[:ui].info(I18n.t("vagrant_libvirt.no_static_ip_on_public_network"))
              end
              domain.wait_for(2) {
                addresses.each_pair do |type, ip|
                  env[:ip_address] = ip[0] if ip[0] != nil
                end
                env[:ip_address] != nil
              }
            end
          end
          terminate(env) if env[:interrupted]
          @logger.info("Got IP address #{env[:ip_address]}")
          @logger.info("Time for getting IP: #{env[:metrics]["instance_ip_time"]}")
          
          # Machine has ip address assigned, now wait till we are able to
          # connect via ssh.
          env[:metrics]["instance_ssh_time"] = Util::Timer.time do
            env[:ui].info(I18n.t("vagrant_libvirt.waiting_for_ssh"))
            retryable(:on => Fog::Errors::TimeoutError, :tries => 60) do
              # If we're interrupted don't worry about waiting
              next if env[:interrupted]

              # Wait till we are able to connect via ssh.
              while true
                # If we're interrupted then just back out
                break if env[:interrupted]
                break if env[:machine].communicate.ready?
                sleep 2
              end            
            end
          end
          terminate(env) if env[:interrupted]
          @logger.info("Time for SSH ready: #{env[:metrics]["instance_ssh_time"]}")

          # Booted and ready for use.
          #env[:ui].info(I18n.t("vagrant_libvirt.ready"))
          
          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          if env[:machine].provider.state.id != :not_created
            # Undo the import
            terminate(env)
          end
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)        
        end
      end
    end
  end
end

