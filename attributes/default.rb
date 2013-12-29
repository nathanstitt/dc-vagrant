default[:account][:login]  = 'vagrant'
default[:account][:ssh_keys]=['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key']

default[:documentcloud][:directory]  = "/home/#{node[:account][:login]}/documentcloud"
default[:documentcloud][:rails_env]  = 'development'

default[:documentcloud][:organization][:name]  = 'Testing Organization'
default[:documentcloud][:organization][:slug]  = 'test'

default[:documentcloud][:account][:email]      = 'testing@documentcloud.org'
default[:documentcloud][:account][:last_name]  = 'Account'
default[:documentcloud][:account][:first_name] = 'Testing'
default[:documentcloud][:account][:password]   = 'testingpw'

default[:gem_versions] = {
  'mime-types'=>'1.24'


}

default['authorization']['sudo']['users'] = [ default[:account][:login] ]
default['authorization']['sudo']['passwordless'] = true

default[:documentcloud][:git][:repository] = 'https://github.com/nathanstitt/documentcloud.git'
default[:documentcloud][:git][:branch]     = 'upstream_master'

default[:nginx][:passenger][:version] = nil
default[:nginx][:config_flags] = '--with-http_ssl_module --with-http_stub_status_module'
default[:nginx][:install_path]        = '/usr/local/nginx'
default[:nginx][:pid]                 = '/var/run/nginx.pid'
default[:nginx][:log_directory]       = '/var/log/nginx'
default[:nginx][:user]                = 'www-data'
default[:nginx][:group]               = 'www-data'
default[:nginx][:worker_processes]    = 4;
default[:passenger][:pre_start]       = []

default[:user][:ssh_keygen]           = true
default[:create_user]                 = true
default[:nginx][:documentcloud][:cert_path] = node[:documentcloud][:directory] + '/secrets/keys/dev.dcloud.org.crt'
default[:nginx][:documentcloud][:key_path]  = node[:documentcloud][:directory] + '/secrets/keys/dev.dcloud.org.key'
default[:nginx][:documentcloud][:host_name] = 'dev.dcloud.org'


default[:chruby][:rubies]  = {'1.8.7' => true}
default[:chruby][:default] = '1.8.7'

default.rails_version = '>=2.3.17'

default['postgresql']['pg_hba'] = [
  {:type => 'local', :db => 'all', :user => 'postgres', :addr => nil, :method => 'ident'},
  {:type => 'local', :db => 'all', :user => 'all', :addr => nil, :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '127.0.0.1/32', :method => 'md5'},
  {:type => 'host', :db => 'all', :user => 'all', :addr => '::1/128', :method => 'md5'}
]
