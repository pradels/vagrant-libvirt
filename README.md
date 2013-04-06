# Vagrant Libvirt Provider

This is a [Vagrant](http://www.vagrantup.com) 1.1+ plugin that adds an
[Libvirt](http://libvirt.org) provider to Vagrant, allowing Vagrant to
control and provision machines via Libvirt toolkit.

**Note:** Actual version (0.0.2) is still a development one. Feedback is
welcome and can help a lot :-)

## Features (Version 0.0.2)

* Vagrant `up`, `destroy`, `suspend`, `resume`, `halt`, `ssh` and `provision` commands.
* Upload box image (qcow2 format) to Libvirt storage pool.
* Create volume as COW diff image for domains.
* Create and boot Libvirt domains.
* SSH into domains.
* Provision domains with any built-in Vagrant provisioner.
* Minimal synced folder support via `rsync`.

## Future work

* More boxes should be available.
* Take a look at [open issues](https://github.com/pradels/vagrant-libvirt/issues?state=open).

## Installation

Install using standard [Vagrant 1.1+](http://downloads.vagrantup.com) plugin installation methods. After
installing, `vagrant up` and specify the `libvirt` provider. An example is shown below.

```
$ vagrant plugin install vagrant-libvirt
```

### Possible problems with plugin installation

In case of problems with building nokogiri gem, install missing development
libraries libxslt and libxml2.

In Ubuntu, Debian, ...
```
$ sudo apt-get install libxslt-dev libxml2-dev libvirt-dev
```

In RedHat, Centos, Fedora, ...
```
# yum install libxslt-devel libxml2-devel libvirt-devel
```

## Vagrant Project Preparation

After installing the plugin (instructions above), the quickest way to get
started is to add Libvirt box and specify all the details manually within
a `config.vm.provider` block. So first, add Libvirt box using any name you
want. This is just an example of Libvirt CentOS 6.4 box available:

```
$ vagrant box add centos64 http://kwok.cz/centos64.box
...
```

And then make a Vagrantfile that looks like the following, filling in
your information where necessary.

```ruby
Vagrant.configure("2") do |config|
  config.vm.define :test_vm do |test_vm|
    test_vm.vm.box = "centos64"
  end

  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "qemu"
    libvirt.host = "example.com"
    libvirt.connect_via_ssh = true
    libvirt.username = "root"
    libvirt.storage_pool_name = "default"
  end
end

```

### Configuration Options

This provider exposes quite a few provider-specific configuration options:

* `driver` - A hypervisor name to access. For now only qemu is supported.
* `host` - The name of the server, where libvirtd is running.
* `connect_via_ssh` - If use ssh tunnel to connect to Libvirt.
* `username` - Username and password to access Libvirt.
* `password` - Password to access Libvirt.
* `storage_pool_name` - Libvirt storage pool name, where box image and
  instance snapshots will be stored.

## Create Project - Vagrant up

In prepared project directory, run following command:

```
$ vagrant up --provider=libvirt
...
```

Vagrant needs to know that we want to use Libvirt and not default VirtualBox.
That's why there is `--provider=libvirt` option specified. Other way to tell
Vagrant to use Libvirt provider is to setup environment variable
`export VAGRANT_DEFAULT_PROVIDER=libvirt`.

### How Project Is Created

1.	Connect to Libvirt localy or remotely via SSH.
2.	Check if box image is available in Libvirt storage pool. If not, upload it to
	remote Libvirt storage pool as new volume. 
3.	Create COW diff image of base box image for new Libvirt domain.
4.	Create and start new domain on Libvirt host.
5.	Check for DHCP lease from dnsmasq server. Store IP address into
	machines *data_dir* for later use, when lease information is not
	available. Then wait till SSH is available.
6.	Sync folders via `rsync` and run Vagrant provisioner on new domain.

## Networks

Networking features in the form of `config.vm.network` are supported only
in bridged format, no hostonly network is supported in current version of
provider.

Example of network interface definition:

```ruby
  config.vm.define :test_vm do |test_vm|
    test_vm.vm.network :bridged, :bridge => "default", :adapter => 1
  end
```

In example above, bridged network adapter connected to network `default` is
defined.

## Obtaining Domain IP Address

Libvirt doesn't provide a way to find out an IP address of running domain. We
can get domains MAC address only. So to get an IP address, Libvirt provider is
checking dnsmasq leases files in `/var/lib/libvirt/dnsmasq` directory. After
IP address is known, it's stored into machines *data_dir* for later use, because
lease information disappears after some time.

Possible problem raises when machines IP was changed since last write into
*data_dir*. Libvirt provider first checks, if IP address matches with domains MAC
address. If not, error is writen to user. As possible solution in this
situation occurs `fping` or `nmap` command to ping whole network.

## Synced Folders

There is minimal support for synced folders. Upon `vagrant up`, the Libvirt
provider will use `rsync` (if available) to uni-directionally sync the folder
to the remote machine over SSH.

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

## Box Format

You can view an example box in the [example_box/directory](https://github.com/pradels/vagrant-libvirt/tree/master/example_box). That directory also contains instructions on how to build a box.

The box is a tarball containing:

* qcow2 image file named `box.img`.
* `metadata.json` file describing box image (provider, virtual_size, format).
* `Vagrantfile` that does default settings for the provider-specific configuration for this provider.

## Development

To work on the `vagrant-libvirt` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

```
$ git clone https://github.com/pradels/vagrant-libvirt.git
$ cd vagrant-libvirt
$ bundle install
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
that uses it, and uses bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=libvirt
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

