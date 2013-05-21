require 'vagrant'

module VagrantPlugins
  module Libvirt

    # This is the base class for a provider for the V2 API. A provider
    # is responsible for creating compute resources to match the
    # needs of a Vagrant-configured system.
    class Provider < Vagrant.plugin('2', :provider)
      def initialize(machine)
        @machine = machine
        raise 'REQUIRE USE RUBY >= 1.9.3 VERSION' if RUBY_VERSION < '1.9.3'
      end

      # This should return an action callable for the given name.
      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      # This method is called if the underying machine ID changes. Providers
      # can use this method to load in new data for the actual backing
      # machine or to realize that the machine is now gone (the ID can
      # become `nil`).
      def machine_id_changed
      end

      # This should return a hash of information that explains how to
      # SSH into the machine. If the machine is not at a point where
      # SSH is even possible, then `nil` should be returned.
      def ssh_info
        # Run a custom action called "read_ssh_info" which does what it says
        # and puts the resulting SSH info into the `:machine_ssh_info` key in
        # the environment.
        #
        # Ssh info has following format..
        #
        #{
        #  :host => "1.2.3.4",
        #  :port => "22",
        #  :username => "mitchellh",
        #  :private_key_path => "/path/to/my/key"
        #}
        env = @machine.action("read_ssh_info")
        env[:machine_ssh_info]
      end

      # This should return the state of the machine within this provider.
      # The state must be an instance of {MachineState}.
      def state
        # Run a custom action we define called "read_state" which does
        # what it says. It puts the state in the `:machine_state_id`
        # key in the environment.
        env = @machine.action("read_state")

        state_id = env[:machine_state_id]

        # Get the short and long description
        short = I18n.t("vagrant_libvirt.states.short_#{state_id}")
        long  = I18n.t("vagrant_libvirt.states.long_#{state_id}")

        # Return the MachineState object
        Vagrant::MachineState.new(state_id, short, long)
      end

      def to_s
        id = @machine.id.nil? ? "new" : @machine.id
        "Libvirt (#{id})"
      end
    end
  end
end

