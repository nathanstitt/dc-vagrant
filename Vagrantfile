# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'erb'
require File.dirname(__FILE__) + "/lib/hash_deep_merge.rb"

# If a config.yml file is present in the same directory,
# Read the configuration settings from it
local_config_file = Pathname.new( File.dirname(__FILE__) + "/config.yml" )
CUSTOM_CONFIG = local_config_file.exist? ? YAML.load( ERB.new( local_config_file.read ).result(binding) ) : {}

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise32"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network :forwarded_port, guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network :private_network, ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.share_folder "v-data", "/vagrant_data", "../data"

  # after provisioning, you can share the documentcloud install directory
  # with your computer like so.
  # Consult http://docs.vagrantup.com/v2/synced-folders/basic_usage.html
  # for details
  #   config.vm.synced_folder "../documentcloud", "/home/dcloud/documentcloud",  :owner => "dcloud"

  if CUSTOM_CONFIG[:sync_folders]
    CUSTOM_CONFIG[:sync_folders].each do | folder |
      config.vm.synced_folder folder[:host], folder[:guest], folder[:options]
    end
  end


  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider :virtualbox do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
  #   vb.customize ["modifyvm", :id, "--memory", "1024"]
  # end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #
  # Enable and configure the chef solo provisioner
  config.vm.provision :chef_solo do |chef|
    # Vagrant Chef Howto - http://bit.ly/RPC4uI
    chef.cookbooks_path = ["cookbooks"]
    chef.add_recipe 'documentcloud'
    chef.add_recipe 'sudo'
    chef.add_recipe 'hostname'

#    Enable extra debugging
#    chef.log_level = :debug

    chef.json = {
      :set_fqdn=>'dev.dcloud.org',
      :documentcloud=>{
        :account=>{
          :login => 'testing@documentcloud.org',
          :password=> 'testingpw'
        },
        :git=>{
          :repository => 'https://github.com/nathanstitt/documentcloud.git',
          :branch     => 'chef'
        }
      },
      'postgresql'=>{
        'password' => {
          'postgres'=>'pgadminpassword'
        }
      }
    }

    HashMerge.perform( chef.json, CUSTOM_CONFIG )

  end
end
