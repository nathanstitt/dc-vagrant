include_recipe "documentcloud::db-server"
include_recipe "documentcloud::app-server"

# Variables from config
install_dir = Pathname.new node[:documentcloud][:directory]
user_id     = node[:account][:login]
rb_version  = node[:chruby][:default]
rb_path     = "/opt/rubies/ruby-#{rb_version}/bin"

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

bash "configure-cloud-crowd" do
  user user_id
  cwd install_dir.to_s
  code <<-EOS
    #{rb_path}/crowd -c config/cloud_crowd/development load_schema
  EOS
  not_if { install_dir.join('cloud_crowd.db').exist? }
end

bash "configure-account" do
  user user_id
  cwd install_dir.to_s
  code <<-BASH
  cat <<EOS > /tmp/provision-account

  organization = Organization.find_or_create_by_id(1)
  organization.slug = "#{node.documentcloud.organization.slug}"
  organization.name = "#{node.documentcloud.organization.name}"
  organization.language = organization.document_language = 'eng'
  organization.save!

  account = Account.find_or_create_by_email("#{node.documentcloud.account.email}")
  account.first_name = "#{node.documentcloud.account.first_name}"
  account.last_name  = "#{node.documentcloud.account.last_name}"
  account.language = account.document_language = 'eng'
  account.hashed_password = BCrypt::Password.create( "#{node.documentcloud.account.password}" )
  account.save!

  unless organization.accounts.exists?( { :email=>"#{node.documentcloud.account.email}" } )
    organization.add_member( account, Account::ADMINISTRATOR )
  end
EOS
  HOME=/home/#{user_id}
  source /usr/local/share/chruby/chruby.sh
  chruby #{rb_version}
  PATH=/bin:$PATH
  env
  bundle install
  bundle exec ./script/runner /tmp/provision-account
  BASH
end
# WTF? Why is HOME & PATH being reset?

include_recipe "documentcloud::search-server"
include_recipe "documentcloud::crowd-node"
include_recipe "documentcloud::crowd-server"
