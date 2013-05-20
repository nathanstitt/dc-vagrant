#
# Cookbook Name: documentcloud
# Recipe: default

include_recipe 'user'
include_recipe 'apt'

node['postgresql']['pg_hba'] = [
  {:type => 'local', :db => 'all', :user => 'postgres', :addr => nil,              :method => 'ident'},
  {:type => 'local', :db => 'all', :user => 'all',      :addr => nil,              :method => 'md5'},
  {:type => 'host',  :db => 'all', :user => 'all',      :addr => '127.0.0.1/32',   :method => 'md5'},
  {:type => 'host',  :db => 'all', :user => 'all',      :addr => '192.168.0.0/16', :method => 'md5'},
  {:type => 'host',  :db => 'all', :user => 'all',      :addr => '10.0.0.0/8',     :method => 'md5'},
  {:type => 'host',  :db => 'all', :user => 'all',      :addr => '::1/128',        :method => 'md5'}
]

node['postgresql']['config']['listen_addresses'] = '*'

include_recipe 'postgresql::server'
include_recipe 'rake'

ssh_known_hosts_entry 'github.com'

# Variables from config
install_dir = Pathname.new node['documentcloud']['directory']
user_id     = node['account']['login']

%w{ postgresql postgresql-contrib }.each do | pkg |
  package pkg
end


include_recipe 'documentcloud::base'

include_recipe "documentcloud::postgresql"

%w{ passenger curb }.each do | gem |
  gem_package gem do
    gem_binary '/usr/bin/gem'
    if node['gems'][ gem ] && node['gems']['version']
      version node['gems'][ gem ]['version']
    end
  end
end


# bash "install-rails" do
#   user "root"
#   cwd install_dir.to_s
#   code <<-EOS
# end

rake 'migrate-db' do
  working_directory install_dir.to_s
  arguments 'db:migrate'
end

ruby "configure-cloud-crowd-host" do
  user 'root'
  cwd install_dir.to_s
  code <<-EOS
    require 'erb'; require 'uri'; require 'yaml'
    ENV['RAILS_ENV'] = "#{node.documentcloud.rails_env}"
    config = YAML.load( ERB.new(File.read( "#{install_dir.join('config', 'document_cloud.yml')}" ) ).result(binding) )[ "#{node.documentcloud.rails_env}" ]
    host = URI.parse( config['cloud_crowd_server'] ).host
    File.open('/etc/hosts','r+') do | file |
      unless file.grep(/#\{host\}/).any?
        file.seek(0,IO::SEEK_END  )
        file.write("127.0.0.1        #\{host\}\n")
      end
    end
  EOS
end

ruby "configure-cloud-crowd" do
  user user_id
  cwd install_dir.to_s
  code <<-EOS
    require 'rubygems'; require 'sqlite3'; require 'cloud-crowd'
    db = SQLite3::Database.new( 'cloud_crowd.db' )
    exists = db.get_first_value( "SELECT name FROM sqlite_master WHERE type='table' AND name='schema_migrations'" )
    if exists.nil?
      db.execute( "CREATE TABLE schema_migrations (Version varchar(255) NOT NULL)" )
      CloudCrowd.configure("config/cloud_crowd/development/config.yml")
      require 'cloud_crowd/models'
      CloudCrowd.configure_database("config/cloud_crowd/development/database.yml", false)
      require 'cloud_crowd/schema.rb'
    end
    db.close
  EOS
  not_if { install_dir.join('cloud_crowd.db').exist? }
end


ruby "configure-account" do
  user user_id
  cwd install_dir.to_s
  code <<-EOS
  require "./config/environment"

  organization = Organization.find_or_create_by_id(1)
  organization.slug = "#{node.documentcloud.organization.slug}"
  organization.name = "#{node.documentcloud.organization.name}"
  organization.save!

  account = Account.find_or_create_by_email("#{node.documentcloud.account.email}")
  account.first_name = "#{node.documentcloud.account.first_name}"
  account.last_name  = "#{node.documentcloud.account.last_name}"
  account.hashed_password = BCrypt::Password.create( "#{node.documentcloud.account.password}" )
  account.save!

  unless organization.accounts.exists?( { :email=>"#{node.documentcloud.account.email}" } )
    organization.add_member( account, Account::ADMINISTRATOR )
  end

  EOS
end

rake 'cloud-crowd-server' do
  user user_id
  arguments 'crowd:server:start'
  working_directory install_dir.to_s
  notifies :run, "rake[cloud-crowd-node]"
  action :run
  not_if "pgrep -f cloud-crowd-server"
end

rake 'cloud-crowd-node' do
  user user_id
  working_directory install_dir.to_s
  arguments 'crowd:node:start'
  action :run
  not_if "pgrep -f cloud-crowd-node"
end

rake 'sunspot-solr' do
  user user_id
  working_directory install_dir.to_s
  arguments 'sunspot:solr:start'
  action :run
  not_if "ps -p `cat #{install_dir}/tmp/pids/sunspot-solr-#{node.documentcloud.rails_env}.pid`"
end


# this needs to come after the source is checkout out and configured
# nginx loads certs from the repo
include_recipe "documentcloud::nginx"
