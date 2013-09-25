module VagrantPlugins
  module ProviderLibvirt
    module Action

      # Setup name for domain and domain volumes.
      class SetNameOfDomain
        def initialize(app, env)
          @app = app
        end

        def call(env)
          require 'securerandom'
          env[:domain_name] = env[:root_path].basename.to_s.dup
          env[:domain_name].gsub!(/[^-a-z0-9_]/i, "")
          env[:domain_name] << "_#{SecureRandom.hex}"

          # Check if the domain name is not already taken
          domain = ProviderLibvirt::Util::Collection.find_matching(
            env[:libvirt_compute].servers.all, env[:domain_name])
          if domain != nil
            raise Vagrant::Errors::DomainNameExists,
              :domain_name => env[:domain_name]
          end

          @app.call(env)
        end
      end

    end
  end
end

