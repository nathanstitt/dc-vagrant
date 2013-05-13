include_recipe 'user'
include_recipe 'apt'
include_recipe 'rake'

node['set_fqdn'] = ( node['host_name'] ? node['host_name'] : 'dev' ) + '.dcloud.org'

include_recipe 'hostname'

install_dir = Pathname.new node['documentcloud']['directory']
user_id     = node['account']['login']

# Apt packages
DEBS=\
%w{ build-essential libcurl4-openssl-dev libssl-dev zlib1g-dev libpcre3-dev ruby1.8 rubygems } +
  %w{ libpq-dev git sqlite3 libsqlite3-dev libpcre3-dev lzop     } +
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
%w{ cloud-crowd sqlite3 pg sanitize right_aws json }.each do | gem |
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
  ssh_keys     node['account']['ssh_keys'] if node.account.ssh_keys
end

git install_dir.to_s do
  repository node.documentcloud.git.repository
  revision   node.documentcloud.git.branch
  user user_id
  action :sync
  notifies :create, 'ruby_block[copy-server-secrets]', :immediately
  not_if { install_dir.exist? }
end

bash "install-rails" do
  user "root"
  cwd install_dir.to_s
  code <<-EOS
    /usr/bin/gem install --no-ri --no-rdoc rails -v `grep -E -o \'RAILS_GEM_VERSION.*[0-9]+\.[0-9]+\.[0-9]+\' config/environment.rb | cut -d\\' -f2`
    rake gems:install
    # nasty, but otherwise cloud crowd will complain later
    # need to implement bundler support
    gem uninstall rack --version '>=1.5'
    chown -R #{user_id} #{install_dir}/log
  EOS
  not_if "gem list rails | grep  `grep -E -o 'RAILS_GEM_VERSION.*[0-9]+\.[0-9]+\.[0-9]+' #{install_dir}/config/environment.rb | cut -d\\' -f2`"
end


ruby_block "copy-server-secrets" do
  block do
    FileUtils.cp_r( install_dir.join('config','server','secrets'), install_dir )
    FileUtils.chown_R user_id, nil, install_dir
  end
  action :nothing
end

hostsfile_entry node.hosts.master.ip do
  hostname  'master.dcloud.org'
  aliases [ node.nginx.documentcloud.host_name ]
  action    :create
end

node.hosts.nodes.each do | host_name, host_config |
  hostsfile_entry node.hosts.nodes[host_name].ip do
    hostname  host_name
    aliases [ "#{host_name}.dcloud.org" ]
    action    :create
  end
end

hostsfile_entry '10.0.2.2' do
  hostname  'vmhost'
  if node.local_host_aliases
    aliases node.local_host_aliases
  end
  action    :create
end


template "/etc/motd" do
  source 'motd.erb'
  owner  'root'
  mode   '0664'
end


