require 'fog'
require 'log4r'

module VagrantPlugins
  module ProviderLibvirt
    module Action
      class ConnectLibvirt
        def initialize(app, env)
          @logger = Log4r::Logger.new('vagrant_libvirt::action::connect_libvirt')
          @app = app
        end

        def call(env)
          # If already connected to libvirt, just use it and don't connect
          # again.
          if ProviderLibvirt.libvirt_connection
            env[:libvirt_compute] = ProviderLibvirt.libvirt_connection
            return @app.call(env)
          end

          # Get config options for libvirt provider.
          config = env[:machine].provider_config
          uri = config.uri

          conn_attr = {}
          conn_attr[:provider] = 'libvirt'
          conn_attr[:libvirt_uri] = uri
          conn_attr[:libvirt_username] = config.username if config.username
          conn_attr[:libvirt_password] = config.password if config.password

          # Setup command for retrieving IP address for newly created machine
          # with some MAC address. Get it from dnsmasq leases table
          ip_command = %q[ awk "/$mac/ {print \$1}" /proc/net/arp ]
          conn_attr[:libvirt_ip_command] = ip_command

          @logger.info("Connecting to Libvirt (#{uri}) ...")
          begin
            env[:libvirt_compute] = Fog::Compute.new(conn_attr)
          rescue Fog::Errors::Error => e
            raise Errors::FogLibvirtConnectionError,
              :error_message => e.message
          end
          ProviderLibvirt.libvirt_connection = env[:libvirt_compute]

          @app.call(env)
        end
      end
    end
  end
end

