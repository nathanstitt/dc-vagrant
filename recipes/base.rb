#
# Cookbook Name: documentcloud
# Recipe: default

include_recipe 'user'
include_recipe 'apt'
include_recipe 'rake'

ssh_known_hosts_entry 'github.com'

# Variables from config
install_dir = Pathname.new node[:documentcloud][:directory]
user_id     = node[:account][:login]
rb_version  = node[:chruby][:default]
rb_path     = "/opt/rubies/ruby-#{rb_version}/bin"

# Apt packages
DEBS=\
%w{ build-essential libcurl4-openssl-dev libssl-dev zlib1g-dev libpcre3-dev poppler-utils  } +
  %w{ libpq-dev git sqlite3 libsqlite3-dev libpcre3-dev lzop  libxml2-dev curl ghostscript } +
  %w{ libxslt-dev libcurl4-gnutls-dev libitext-java graphicsmagick pdftk xpdf    }
DEBS.each do | pkg |
  package pkg
end


include_recipe 'hostname'

if node[:create_user]
  include_recipe 'sudo'

  user_account 'user-account' do
    username     user_id
    create_group true
    ssh_keys     node[:account][:ssh_keys] if node.account.ssh_keys
  end
end

include_recipe "ruby_install"
ruby_install_ruby "ruby #{rb_version}"

# bash "set-ruby-version" do
#   code <<-EOS
#          update-alternatives --install /usr/bin/ruby ruby /opt/rubies/ruby-#{rb_version}.7/bin/ruby 500 \
#              --slave /usr/bin/erb     erb    /opt/rubies/ruby-#{rb_version}.7/bin/erb    \
#              --slave /usr/bin/irb     irb    /opt/rubies/ruby-#{rb_version}.7/bin/irb    \
#              --slave /usr/bin/rake    rake   /opt/rubies/ruby-#{rb_version}.7/bin/rake   \
#              --slave /usr/bin/ri      ri     /opt/rubies/ruby-#{rb_version}.7/bin/ri     \
#              --slave /usr/bin/rdoc    rdoc   /opt/rubies/ruby-#{rb_version}.7/bin/rdoc   \
#              --slave /usr/bin/testrb  testrb /opt/rubies/ruby-#{rb_version}.7/bin/testrb

#          update-alternatives --install /usr/bin/gem  gem  /opt/rubies/ruby-#{rb_version}.7/bin/gem  500
#   EOS
#   not_if "ruby -v | grep #{rb_version}"
# end


include_recipe "chruby"

bash "set-non-interactive-chruby" do
  user user_id
  code <<-EOS
    echo source /usr/local/share/chruby/chruby.sh >> /home/#{user_id}/.bashrc
    echo chruby ruby-#{rb_version} >> /home/#{user_id}/.bashrc
  EOS
  not_if "grep chruby /home/#{user_id}/.bashrc"
end

bash "set-root-non-interactive-chruby" do
  code <<-EOS
    echo source /usr/local/share/chruby/chruby.sh   >> /root/.bashrc
    echo chruby ruby-#{rb_version} >> /root/.bashrc
  EOS
  not_if "grep chruby /root/.bashrc"
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

# Ruby Gems

bash "no-rdoc" do
  user user_id
  cwd "/home/#{user_id}"
  code <<-EOS
    echo gem: --no-document >> .gemrc
  EOS
  not_if "grep no-document .gemrc"
end

%w{ bundler mime-types sqlite3 pg cloud-crowd libxml-ruby }.each do | gem |
  cmd = "#{rb_path}/gem install #{gem}"
  cmd << " --version #{node.gem_versions[gem]}" if node.gem_versions[ gem ]
  bash "install-#{gem}-gem" do
    code <<-EOS
       #{cmd}
    EOS
    not_if "gem list -i #{gem}|grep #{gem}"
  end
end


bash "install-rails" do
  user user_id
  flags "-l"
  cwd install_dir.to_s 
  code <<-EOS
     bundle install
  EOS
end

rake 'migrate-db' do
  working_directory install_dir.to_s
  arguments 'db:migrate'
end



template "/etc/motd" do
  source 'motd.erb'
  owner  'root'
  mode   '0664'
end

