#
# Cookbook Name: documentcloud
# Recipe: default

include_recipe 'user'
include_recipe 'apt'
include_recipe 'postgresql::server'
include_recipe 'rake'

ssh_known_hosts_entry 'github.com'

# Variables from config
install_dir = Pathname.new node[:documentcloud][:directory]
user_id     = node[:account][:login]

# Apt packages
DEBS=\
  %w{ build-essential libcurl4-openssl-dev libssl-dev zlib1g-dev libpcre3-dev ruby1.8 rubygems } +
  %w{ postgresql postgresql-contrib libpq-dev git sqlite3 libsqlite3-dev libpcre3-dev lzop     } +
  %w{ libxslt-dev libcurl4-gnutls-dev libitext-java graphicsmagick pdftk xpdf poppler-utils    } +
  %w{ libreoffice libreoffice-java-common tesseract-ocr ghostscript libxml2-dev curl           }
DEBS.each do | pkg |
  package pkg
end

# Tesseract language packs
%w{ eng deu spa fra chi-sim chi-tra }.each do | language_code |
  package 'tesseract-ocr-' + language_code
end

# Ruby Gems
%w{ cloud-crowd sqlite3 pg bundler passenger }.each do | gem |
  gem_package gem do
    gem_binary '/usr/bin/gem'
    if node['gems'][ gem ] && node['gems']['version']
      version node['gems'][ gem ]['version']
    end
  end
end


user_account 'user-account' do
  username     user_id
  create_group true
  ssh_keygen   true
  ssh_keys     node[:account][:ssh_keys] if node.account.ssh_keys
end

git install_dir.to_s do
  repository node.documentcloud.git.repository
  revision   node.documentcloud.git.branch
  user user_id
  action :sync
  notifies :create, 'ruby_block[copy-server-secrets]', :immediately
  not_if { install_dir.exist? }
end

ruby_block "copy-server-secrets" do
  block do
    FileUtils.cp_r( install_dir.join('config','server','secrets'), install_dir )
    FileUtils.chown_R user_id, nil, install_dir
  end
  action :nothing
end

include_recipe "documentcloud::postgresql"

bash "install-rails" do
  user "root"
  cwd install_dir.to_s
  code <<-EOS
    bundle install
    # # nasty, but otherwise cloud crowd will complain later
    # # need to implement bundler support
    # gem uninstall rack --version '>=1.5'
    # chown -R #{user_id} #{install_dir}/log
  EOS
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
#  not_if { install_dir.join('cloud_crowd.db').exist? }
end

rake 'cloud-crowd-server' do
  user user_id
  arguments 'crowd:server:start'
  working_directory install_dir.to_s
  notifies :run, "rake[cloud-crowd-node]"
  action :run
  not_if { install_dir.join('tmp','pids','server.pid').exist? }
end

rake 'cloud-crowd-node' do
  user user_id
  working_directory install_dir.to_s
  arguments 'crowd:node:start'
  action :run
  not_if { install_dir.join('tmp','pids','node.pid').exist? }
end

rake 'sunspot-solr' do
  user user_id
  working_directory install_dir.to_s
  arguments 'sunspot:solr:start'
  action :run
  not_if { install_dir.join('tmp','pids',"sunspot-solr-#{node.documentcloud.rails_env}.pid").exist? }
end

template "/etc/motd" do
  source 'motd.erb'
  owner  'root'
  mode   '0664'
end

# this needs to come after the source is checkout out and configured
# nginx loads certs from the repo
include_recipe "documentcloud::nginx"
