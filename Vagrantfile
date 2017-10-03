# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

$instance_name_prefix = "k8s"
$num_instances = 1

Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.

  config.vm.box = "centos/7"
  #config.vm.network "public_network", bridge: "enp3s0"
  #config.vm.network "public_network", :adapter=>1 , type: "dhcp", :bridge => "enp3s0"
  config.vm.network "public_network", type: "dhcp", :bridge => "enp3s0"
  config.vm.usable_port_range = (2000..2500)

  config.vm.provider "virtualbox" do |vb|
     # Display the VirtualBox GUI when booting the machine
     vb.gui = false
  #   # Customize the amount of memory on the VM:
     vb.memory = "3072"
     vb.cpus = 3
  end

  # NODES:
  (1..$num_instances).each do |i|
    config.vm.define vm_name = "%s-%02d" % [$instance_name_prefix, i] do |node|
     node.vm.box = "centos/atomic-host"
     node.vm.hostname = vm_name
     node.vm.provision "shell", inline: "echo hello from %s" % [node.vm.hostname]
     node.vm.provision "shell", inline: <<-SHELL
      sudo cp -r ~vagrant/.ssh ~/  # This will allow us to ssh into root with existing vagrant key
      #sudo apt-get update
      #sudo apt-get install -y git docker ansible
      #sudo yum install -y git docker ansible curl tar zip unzip
      #ssh-copy-id
     SHELL
     File.open("ssh_config", "w+") { |file| file.write("boo" ) }
    end
  end

  # MASTER:
  config.vm.define vm_name = "%s-master" % [$instance_name_prefix] , primary: true do |k8smaster|
    #k8smaster.vm.hostname = "#{k8smaster}"
    #k8smaster.vm.hostname = "%s" % [ k8smaster ]
    k8smaster.vm.hostname = vm_name
    k8smaster.vm.network "forwarded_port", guest: 80, host: 2080, auto_correct: true
    k8smaster.vm.network "forwarded_port", guest: 443, host: 2443, auto_correct: true
    k8smaster.vm.provision :shell, inline: "echo hello from %s" % [k8smaster.vm.hostname]
    k8smaster.vm.provision "shell", inline: <<-SHELL
     sudo cp -r ~vagrant/.ssh ~/  # This will allow us to ssh into root with existing vagrant key
     #sudo apt-get update
     #sudo apt-get install -y git docker ansible
     sudo yum install -y git docker ansible curl tar zip unzip
     curl -SL https://github.com/ReSearchITEng/kubeadm-playbook/archive/master.tar.gz | tar xvz
    SHELL

  end
  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
end
