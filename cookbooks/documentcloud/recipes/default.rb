#
# Cookbook Name: documentcloud
# Recipe: default

include_recipe 'user'
include_recipe 'apt'
include_recipe 'postgresql::server'
include_recipe 'rake'

# Variables from config
install_dir = Pathname.new node[:documentcloud][:directory]
user_id     = node[:account][:login]

# Apt packages
DEBS=\
  %w{ build-essential libcurl4-openssl-dev libssl-dev zlib1g-dev libpcre3-dev ruby1.8 rubygems } +
  %w{ postgresql libpq-dev git sqlite3 libsqlite3-dev libpcre3-dev lzop libxml2-dev curl       } +
  %w{ libxslt-dev libcurl4-gnutls-dev libitext-java graphicsmagick pdftk xpdf poppler-utils    } +
  %w{ libreoffice libreoffice-java-common tesseract-ocr ghostscript                            }
DEBS.each do | pkg |
  package pkg
end

# Tesseract language packs
%w{ eng deu spa fra chi-sim chi-tra }.each do | language_code |
  package 'tesseract-ocr-' + language_code
end

# Ruby Gems
%w{ cloud-crowd sqlite3 pg sanitize right_aws json passenger }.each do | gem |
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

ssh_known_hosts_entry 'github.com'

git install_dir.to_s do
  repository node.documentcloud.git.repository
  revision  node.documentcloud.git.branch
  user user_id
  action :checkout
end

ruby_block "copy-server-secrets" do
  block do
    FileUtils.cp_r( install_dir.join('config','server','secrets'), install_dir ) unless install_dir.join('secrets').exist?
  end
end

include_recipe "documentcloud::postgresql"

bash "install-rails" do
  user "root"
  cwd install_dir.to_s
  code <<-EOS
    /usr/bin/gem install --no-ri --no-rdoc rails -v `grep -E -o \'RAILS_GEM_VERSION.*[0-9]+\.[0-9]+\.[0-9]+\' config/environment.rb | cut -d\\' -f2`
    rake gems:install
    # nasty, but otherwise cloud crowd will complain later
    # need to implement bundler support
    gem uninstall rack --version '>=1.5'
  EOS
  not_if "gem list rails | grep  `grep -E -o 'RAILS_GEM_VERSION.*[0-9]+\.[0-9]+\.[0-9]+' #{install_dir}/config/environment.rb | cut -d\\' -f2`"
end

rake 'migrate-db' do
  working_directory install_dir.to_s
  arguments 'db:migrate'
end

rake 'cloud-crowd-server' do
  user user_id
  arguments 'crowd:server:start'
  working_directory install_dir.to_s
  notifies :run, "rake[cloud-crowd-node]"
  action :run
  not_if { File.exists?(install_dir.join('tmp','pids','server.pid') ) }
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
  not_if { File.exists?( install_dir.join('cloud_crowd.db') ) }
end


rake 'cloud-crowd-node' do
  user user_id
  working_directory install_dir.to_s
  arguments 'crowd:node:start'
  action :run
  not_if { File.exists?(install_dir.join('tmp','pids','node.pid') ) }
end

rake 'sunspot-solr' do
  user user_id
  working_directory install_dir.to_s
  arguments 'sunspot:solr:start'
  action :run
  not_if { File.exists?(install_dir.join('tmp','pids',"sunspot-solr-#{node.documentcloud.rails_env}.pid") ) }
end

template "/etc/motd" do
  source 'motd.erb'
  owner  'root'
  mode   '0664'
end

# this needs to come after the source is checkout out and configured
# nginx loads certs from the repo
include_recipe "documentcloud::nginx"
