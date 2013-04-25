Description
===========

Installs and configures a DocumentCloud instance

Requirements
============

## Platforms

* Debian, Ubuntu, *May* run on Red Hat/CentOS.  Reports are welcome


Attributes
==========

See `attributes/default.rb` file for a list of all
attributes and their default values.

If you are using vagrant, they can be customized in the Vagrantfile:

    Vagrant.configure("2") do |config|
      config.vm.provision :chef_solo do |chef|
        chef.json = {
          :set_fqdn=>'dev.dcloud.org',
          :account => {
            :login=>'bob',
            'hostname'=>'dev.dcloud.org',
            :documentcloud=>{
              :directory => '/opt/documentcloud'
            }
         }
    end


