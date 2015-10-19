# 0.0.15 (Feb 01, 2014)
* Minimum vagrant version supported is 1.4.3
* Add support for port forwarding (by Ryan Petrello <ryan@ryanpetrello.com>)
* Improve network device creation (by Brian Pitts <brian@polibyte.com>)
* Improvements to NFS sharing (by Matt Palmer and Jason DeTiberus <detiber@gmail.com>)
* Provisioning fixes for Vagrant 1.4 (by @keitwb)

# 0.0.14 (Jan. 21, 2014)
* Vagrant 1.4 compatibility fixes (by Dmitry Vasilets <pronix.service@gmail.com>)
* Improve how VMs IP address is discovered  (by Brian Pitts <brian@polibyte.com>)
* Add cpu_mode parameter (by Jordan Tardif <jordan.tardi@gmail.com>)
* Add disk_bus parameter (by Brian Pitts <brian@polibyte.com>)
* Fixes to some error output (by Matthiew Coudron <matthieu.coudron@lip6.fr>)
* Add parameters for booting kernel file (by Matthiew Coudron <matthieu.coudron@lip6.fr>)
* Add default_prefix parameter (by James Shubin <purpleidea@gmail.com>)
* Improve network creation (by Brian Pitts <brian@polibyte.com>)
* Replace default_network parameter with management_network parameters (by Brian Pitts <brian@polibyte.com>)

# 0.0.13 (Dec. 12, 2013)
* Allow to use nested virtualization again (by Artem Chernikov <achernikov@suse.com>)

# 0.0.12 (Dec. 03, 2013)

* Proxy ssh through libvirt host, if libvirt is connected via ssh(by @erik-smit)
* Fix wrong nfs methods call (by rosario.disomma@dreamhost.com)
* adding the nfs share on start (by @cp16net)
* Mention vagrant-mutate  (by Brian Pitts <brian@polibyte.com>)
* Fix box metadata error keys (by Brian Pitts <brian@polibyte.com>)
* Fix selinux should working
* Mention compatibility with sahara (by Brian Pitts <brian@polibyte.com>)
* Add default network and ssh key file parameters (by Mathilde Ffrench <ffrench.mathilde@gmail.com>)

# 0.0.11 (Oct. 20, 2013)

* BUG FIX  close #70 undefine machine id should be after all operations
* BUG FIX  close #76 correct uri for different virtualizations
* BUG FIX  close #72 possibility to give VMs a name
* Delete any snapshots when destroying domain (by Brian Pitts <brian@polibyte.com>)
* Add reload command (by Brian Pitts <brian@polibyte.com>)
* Update README (by <brett@apache.org>)

# 0.0.10 (Oct. 7, 2013)

* Delete files from destination to avoid confusions(by <skullzeek@gmail.com>)

# 0.0.9 (September 29, 2013)

* fixed version of nokogiri = 1.5.10(by Brian Pitts <brian@polibyte.com>)
* fix issue with network activation (by Brian Pitts <brian@polibyte.com>)
* restrict version of vagrant > 1.3.0

# 0.0.8 (September 25, 2013)

* enable parallelization (by Brian Pitts <brian@polibyte.com>)

# 0.0.7

* Fixed namespace collision with ruby-libvirt library which used by
  vagrant-kvm provider.(by Hiroshi Miura)
* enable nested virtualization for amd (by Jordan Tardif <jordan@dreamhost.com>)

# 0.0.6 (Jul 24, 2013)

* Synced folder via NFS support.
* Routed private network support.
* Configurable ssh parameters in Vagrantfile via `config.ssh.*`.
* Fixed uploading base box image to storage pool bug (buffer was too big).

# 0.0.5 (May 10, 2013)

* Private networks support.
* Creating new private networks if ip is specified and network is not
  available.
* Removing previously created networks, if there are no active connections.
* Guest interfaces configuration.
* Setting guest hostname (via `config.vm.hostname`).

# 0.0.4 (May 5, 2013)

* Bug fix in number of parameters for provisioner.
* Handle box URL when downloading a box.
* Support for running ssh commands like `vagrant ssh -c "bash cli"`

# 0.0.3 (Apr 11, 2013)

* Cpu and memory settings for domains.
* IP is parsed from dnsmasq lease files only, no saving of IP address into
  files anymore.
* Tool for preparation RedHat Linux distros for box image added.

# 0.0.2 (Apr 1, 2013)

* Halt, suspend, resume, ssh and provision commands added.
* IP address of VM is saved into `$data_dir/ip` file.
* Provider can be set via `VAGRANT_DEFAULT_PROVIDER` env variable.

# 0.0.1 (Mar 26, 2013)

* Initial release.
