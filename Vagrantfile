# -*- mode: ruby -*-
# vi: set ft=ruby :

#### REQUIRED PLUGINS:
# vagrant-berkshelf
# vagrant-vbguest
# vagrant-omnibus

require 'yaml'
require 'erb'
require File.dirname(__FILE__) + "/lib/hash_deep_merge.rb"

# If a config.yml file is present in the same directory,
# Read the configuration settings from it
local_config_file = Pathname.new( File.dirname(__FILE__) + "/config.yml" )
CONFIG = local_config_file.exist? ? YAML.load( ERB.new( local_config_file.read ).result(binding) ) : {}
CONFIG.default_proc = proc do |h, k|
  case k
  when String then sym = k.to_sym; h[sym] if h.key?(sym)
  when Symbol then str = k.to_s; h[str] if h.key?(str)
  end
end

Vagrant.configure("2") do |config|

  config.omnibus.chef_version = "11.8.2"

  config.vm.define "development" do | dev |
    config.vm.provider "virtualbox" do |v|
      v.memory = 2048
    end
    dev.vm.network :private_network, ip: "192.168.33.10"

    dev.vm.box = "saucy64"
    dev.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/saucy/current/saucy-server-cloudimg-amd64-vagrant-disk1.box"

    if CONFIG['sync_folders']
      CONFIG['sync_folders'].each do | folder |
        config.vm.synced_folder folder['host'], folder['guest'], folder['options']
      end
    end

    dev.vm.provision :chef_solo do |chef|
      chef.add_recipe 'documentcloud'

      #    Enable extra debugging
      chef.log_level = :debug
      chef.json = {
        :set_fqdn=>'dev.dcloud.org',

        :documentcloud=>{
          :account=>{
          :login => 'testing@documentcloud.org',
          :password=> 'testingpw'
        },
          :git=>{
            :repository => 'https://github.com/documentcloud/documentcloud.git',
            :branch     => 'master'
          }
        },
        'postgresql'=>{
          'password' => {'postgres'=>'pgadminpassword' }
        }
      }
      HashMerge.perform( chef.json, CONFIG )
      chef.run_list = [
        "recipe[documentcloud::development]"
      ]
    end
  end


  # config.vm.provider :aws do |aws, override|
  #   aws.access_key_id     = ENV["AWS_ACCESS_KEY_ID"]
  #   aws.secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
  #   aws.keypair_name      = ENV["AWS_KEYPAIR"]

  #   aws.ami = "ami-6d0c2204" # Ubuntu 13.10 64bit us-east-1

  #   override.ssh.username = "ubuntu"
  #   override.ssh.private_key_path = ENV["AWS_SSH_KEY_PATH"]

  #   aws.vm.provision :chef_solo do |chef|
  #     chef.json = {
  #       :set_fqdn=>'worker-1.dcloud.org',
  #     }
  #     HashMerge.perform( chef.json, CONFIG )
  #     chef.run_list = [
  #       "recipe[documentcloud::default]",
  #       "recipe[documentcloud::crowd-node]"
  #     ]
  #   end
  # end

  # # All Vagrant configuration is done here. The most common configuration
  # # options are documented and commented below. For a complete reference,
  # # please see the online documentation at vagrantup.com.

  # config.vm.hostname = "documentcloud-berkshelf"
  # config.omnibus.chef_version = "11.8.2"

  # # Every Vagrant virtual environment requires a box to build off of.

  # # Every Vagrant virtual environment requires a box to build off of.
  # # config.vm.box = "precise32"
  # # config.vm.box_url = "http://hacks-hackers-buenos-aires.s3.amazonaws.com/documentcloud-vagrant-precise32.box"

  # # config.vm.box      = 'opscode-ubuntu-13.10'
  # # config.vm.box_url  = 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box'

  # config.vm.box = "saucy64"
  # config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/saucy/current/saucy-server-cloudimg-amd64-vagrant-disk1.box"

  # # Assign this VM to a host-only network IP, allowing you to access it
  # # via the IP. Host-only networks can talk to the host machine as well as
  # # any other machines on the same network, but cannot be accessed (through this
  # # network interface) by any external networks.
  # config.vm.network :private_network, ip: "33.33.33.10"

  # # Create a public network, which generally matched to bridged network.
  # # Bridged networks make the machine appear as another physical device on
  # # your network.

  # # config.vm.network :public_network

  # # Create a forwarded port mapping which allows access to a specific port
  # # within the machine from a port on the host machine. In the example below,
  # # accessing "localhost:8080" will access port 80 on the guest machine.

  # # Share an additional folder to the guest VM. The first argument is
  # # the path on the host to the actual folder. The second argument is
  # # the path on the guest to mount the folder. And the optional third
  # # argument is a set of non-required options.
  # # config.vm.synced_folder "../data", "/vagrant_data"

  # # Provider-specific configuration so you can fine-tune various
  # # backing providers for Vagrant. These expose provider-specific options.
  # # Example for VirtualBox:
  # #
  # # config.vm.provider :virtualbox do |vb|
  # #   # Don't boot with headless mode
  # #   vb.gui = true
  # #
  # #   # Use VBoxManage to customize the VM. For example to change memory:
  # #   vb.customize ["modifyvm", :id, "--memory", "1024"]
  # # end
  # #
  # # View the documentation for the provider you're using for more
  # # information on available options.

  # # The path to the Berksfile to use with Vagrant Berkshelf
  # # config.berkshelf.berksfile_path = "./Berksfile"

  # # Enabling the Berkshelf plugin. To enable this globally, add this configuration
  # # option to your ~/.vagrant.d/Vagrantfile file
  # config.berkshelf.enabled = true
  # # An array of symbols representing groups of cookbook described in the Vagrantfile
  # # to exclusively install and copy to Vagrant's shelf.
  # # config.berkshelf.only = []

  # # An array of symbols representing groups of cookbook described in the Vagrantfile
  # # to skip installing and copying to Vagrant's shelf.
  # # config.berkshelf.except = []

  # config.vm.provision :chef_solo do |chef|
  #   # Vagrant Chef Howto - http://bit.ly/RPC4uI
  #   chef.cookbooks_path = ["cookbooks"]
  #   chef.add_recipe 'documentcloud'
  #   if CONFIG['authorization']
  #     chef.add_recipe 'sudo'
  #   end
  #   chef.add_recipe 'hostname'

  #   #    Enable extra debugging
  #   #    chef.log_level = :debug

  #   chef.json = {
  #     :set_fqdn=>'dev.dcloud.org',
  #     :documentcloud=>{
  #       :account=>{
  #       :login => 'testing@documentcloud.org',
  #       :password=> 'testingpw'
  #     },
  #       :git=>{
  #         :repository => 'https://github.com/documentcloud/documentcloud.git',
  #         :branch     => 'master'
  #       }
  #     },
  #     'postgresql'=>{
  #       'password' => {
  #       'postgres'=>'pgadminpassword'
  #     }
  #     }
  #   }
  #   HashMerge.perform( chef.json, CONFIG )
  #     chef.run_list = [
  #         "recipe[documentcloud::development]"
  #     ]
  # end

  # # config.vm.provision :chef_solo do |chef|
  # #   chef.json = {
  # #     :mysql => {
  # #       :server_root_password => 'rootpass',
  # #       :server_debian_password => 'debpass',
  # #       :server_repl_password => 'replpass'
  # #     }
  # #   }

  # #   chef.run_list = [
  # #       "recipe[documentcloud::default]"
  # #   ]
  # # end
end
