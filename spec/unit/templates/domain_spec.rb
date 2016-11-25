require "support/sharedcontext"

require "vagrant-libvirt/config"
require "vagrant-libvirt/util/erb_template"

describe "templates/domain" do

  include_context "unit"

  class DomainTemplateHelper < VagrantPlugins::ProviderLibvirt::Config
    include VagrantPlugins::ProviderLibvirt::Util::ErbTemplate
  end

  let(:domain) { DomainTemplateHelper.new }
  let(:xml_expected) { File.read(File.join(File.dirname(__FILE__), test_file)) }

  context "when only defaults used" do
    let(:test_file) { 'domain_defaults.xml' }
    it "renders template" do
      domain.finalize!
      expect(domain.to_xml('domain')).to eq xml_expected
    end
  end

  context "when all settings enabled" do
    before do
      domain.instance_variable_set('@domain_type', 'kvm')
      domain.cpu_mode = 'custom'
      domain.cpu_feature({:name => 'AAA', :policy => 'required'})
      domain.machine_type = 'pc-compatible'
      domain.machine_arch = 'x86_64'
      domain.loader = '/efi/loader'
      domain.boot('network')
      domain.boot('cdrom')
      domain.boot('hd')
      domain.emulator_path = '/usr/bin/kvm-spice'
      domain.instance_variable_set('@domain_volume_path', '/var/lib/libvirt/images/test.qcow2')
      domain.instance_variable_set('@domain_volume_cache', 'unsafe')
      domain.disk_bus = 'ide'
      domain.storage(:file, {:path => 'test-disk1.qcow2'})
      domain.storage(:file, {:path => 'test-disk2.qcow2'})
      domain.disks.each do |disk|
        disk[:absolute_path] = '/var/lib/libvirt/images/' + disk[:path]
      end
      domain.storage(:file, {:device => :cdrom})
      domain.storage(:file, {:device => :cdrom})
      domain.channel(:type => 'unix',
                     :target_name => 'org.qemu.guest_agent.0',
                     :target_type => 'virtio')
      domain.channel(:type => 'unix',
                     :target_type => 'guestfwd',
                     :target_address => '192.0.2.42',
                     :target_port => '4242',
                     :source_path => '/tmp/foo')
      domain.random(:model => 'random')
      domain.serial(:type => 'file', :source => {:path => '/var/log/vm_consoles/machine.log'})
      domain.pci(:bus => '0x06', :slot => '0x12', :function => '0x5')
      domain.pci(:bus => '0x03', :slot => '0x00', :function => '0x0')
      domain.usb(:bus => '1', :device => '2', :vendor => '0x1234', :product => '0xabcd')
      domain.redirdev(:type => 'tcp', :host => 'localhost', :port => '4000')
      domain.redirfilter(:class => '0x0b', :vendor => '0x08e6',
                         :product => '0x3437', :version => '2.00', :allow => 'yes')
      domain.tpm_path = '/dev/tpm0'
    end
    let(:test_file) { 'domain_all_settings.xml' }
    it "renders template" do
      domain.finalize!
      expect(domain.to_xml('domain')).to eq xml_expected
    end
  end
end
