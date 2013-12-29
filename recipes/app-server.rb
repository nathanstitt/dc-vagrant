include_recipe "documentcloud::base"

nginx_path  = Pathname.new node[:nginx][:install_path]
nginx_conf  = nginx_path.join( 'conf','nginx.conf' )

bash "install passenger/nginx" do
  user "root"
  code <<-BASH
     gem install passenger
     passenger-install-nginx-module --auto --auto-download --prefix=#{nginx_path}  --extra-configure-flags='#{node[:nginx][:config_flags]}'
    mkdir -p #{nginx_path}/conf/sites-enabled
  cat <<EOS > /usr/local/nginx/conf/passenger.conf
  passenger_root `passenger-config --root`;
  passenger_ruby /opt/rubies/ruby-#{node['chruby']['default']}/bin/ruby;
  passenger_default_user www-data;
  passenger_pool_idle_time 0;
  passenger_max_pool_size 4;
EOS

  BASH
  not_if { nginx_path.exist? }
end

directory node.nginx.log_directory do
  owner node[:nginx][:user]
  group node[:nginx][:group]
  mode 0644
  action :create
  not_if { File.exists?( node.nginx.log_directory ) }
end


template nginx_conf.to_s do
  source 'nginx.conf.erb'
  mode   '0664'
  notifies :enable, "service[nginx]"
  notifies :start, "service[nginx]"
end

template '/etc/init.d/nginx' do
  source 'nginx.init.erb'
  mode   '0711'
end


template nginx_path.join('conf','sites-enabled','default.conf').to_s do
  source 'nginx_site.conf.erb'
  mode   '0664'
  notifies :enable, "service[nginx]"
  notifies :start, "service[nginx]"
end

template nginx_path.join('conf','documentcloud.conf').to_s do
  source 'documentcloud.conf.erb'
  mode   '0664'
  notifies :enable, "service[nginx]"
  notifies :start, "service[nginx]"
end



service "nginx" do
  supports :restart => true, :start => true, :stop => true, :reload => true
  action :start
end
