# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'erb'
require File.dirname(__FILE__) + "/lib/hash_merge.rb"

# If a config.yml file is present in the same directory,
# Read the configuration settings from it
CONFIG = {
  'hosts' => {
    'master' =>{
      'ip' =>'192.168.33.10'
    },
    'nodes' => {
      'node-1' => { 'ip'=> '192.168.33.11' },
      'node-2' => { 'ip'=> '192.168.33.12' }
      # 'node-3' => { :ip=> '192.168.33.13' }
    }
  },
  'documentcloud'=> {
    'account'=>{
      'email' => 'testing@documentcloud.org',
      'password' => 'testingpw'
    },
    'git' =>{
      'repository' => 'https://github.com/documentcloud/documentcloud.git',
      'branch'     => 'master'
    }
  },
  'postgresql'=>{
    'password' => {
      'postgres'=>'pgadminpassword'
    }
  }
}

if ( local_config_file = Pathname.new( File.dirname(__FILE__) + "/config.yml" ) ).exist?
  HashMerge.perform(
    CONFIG, YAML.load( ERB.new( local_config_file.read ).result(binding) )
  )
end

Vagrant.configure("2") do |config|

  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise32"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"

  if CONFIG['sync_folders']
    CONFIG['sync_folders'].each do | folder |
      config.vm.synced_folder folder['host'], folder['guest'], folder['options']
    end
  end

  config.vm.define 'master' do | master |
    master.vm.network :private_network, ip: CONFIG['hosts']['master']['ip']
    master.vm.synced_folder './package_cache', '/var/cache/apt/archives/'

    master.vm.provision :chef_solo do |chef|
      # Vagrant Chef Howto - http://bit.ly/RPC4uI
      chef.cookbooks_path = ["cookbooks"]
      chef.add_recipe 'documentcloud'
      if CONFIG['authorization']
        chef.add_recipe 'sudo'
      end
      chef.json = {
        'host_name'=>"master"
      }
      HashMerge.perform( chef.json, CONFIG )

    end
  end

  CONFIG['hosts']['nodes'].each do | host_name, host_config |

    config.vm.define host_name do |node|
      node.vm.network :private_network, ip: CONFIG['hosts']['nodes'][host_name]['ip']
      node.vm.synced_folder './package_cache', '/var/cache/apt/archives/'

      node.vm.provision :chef_solo do |chef|
        chef.cookbooks_path = ["cookbooks"]
        chef.json = {
          'host_name' => host_name
        }
        chef.add_recipe 'documentcloud::node'
        if CONFIG['authorization']
          chef.add_recipe 'sudo'
        end
        if CONFIG['sync_folders']
          CONFIG['sync_folders'].each do | folder |
            config.vm.synced_folder folder['host'], folder['guest'], folder['options']
          end
        end
        HashMerge.perform( chef.json, CONFIG )
      end


    end
  end


end
