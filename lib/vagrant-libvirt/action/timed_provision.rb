require "vagrant-libvirt/util/timer"

module VagrantPlugins
  module Libvirt
    module Action
      # This is the same as the builtin provision except it times the
      # provisioner runs.
      class TimedProvision < Vagrant::Action::Builtin::Provision
        def run_provisioner(env, name, p)
          env[:ui].info(I18n.t("vagrant.actions.vm.provision.beginning",
                               :provisioner => name))

          timer = Util::Timer.time do
            super
          end

          env[:metrics] ||= {}
          env[:metrics]["provisioner_times"] ||= []
          env[:metrics]["provisioner_times"] << [p.class.to_s, timer]
        end
      end
    end
  end
end
