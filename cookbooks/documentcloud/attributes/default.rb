default[:account][:login]  = 'dcloud'
default[:account][:ssh_keys]=[]

default[:documentcloud][:directory]  = "/home/#{node[:account][:login]}/documentcloud"
default[:documentcloud][:rails_env]  = 'development'
default[:gems] = {}

default[:documentcloud][:git][:repository] = 'https://github.com/documentcloud/documentcloud.git'
default[:documentcloud][:git][:branch]     = 'master'

default[:nginx][:passenger][:version] = nil
default[:nginx][:config_flags] = '--with-http_ssl_module --with-http_stub_status_module'
default[:nginx][:install_path]        = '/usr/local/nginx'
default[:nginx][:pid]                 = '/var/run/nginx.pid'
default[:nginx][:log_directory]       = '/var/log/nginx'
default[:nginx][:user]                = 'www-data'
default[:nginx][:group]               = 'www-data'
default[:nginx][:worker_processes]    = 4;

default[:passenger][:pre_start]       = []

default[:nginx][:documentcloud][:cert_path] = node[:documentcloud][:directory] + '/secrets/keys/dev.dcloud.org.crt'
default[:nginx][:documentcloud][:key_path]  = node[:documentcloud][:directory] + '/secrets/keys/dev.dcloud.org.key'
default[:nginx][:documentcloud][:host_name] = 'dev.dcloud.org'

default.rails_version = '>=2.3.17'

node['postgresql']['pg_hba'] = [
  {:type => 'local', :db => 'all', :user => 'postgres', :addr => nil, :method => 'ident'},
  {:type => 'local', :db => 'all', :user => 'all', :addr => nil, :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '127.0.0.1/32', :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '::1/128', :method => 'md5'}
]

