include_recipe "documentcloud::base"

template '/etc/init.d/documentcloud-crowd-server-node' do
  source 'rake-service.init.erb'
  mode   '0755'
  variables({
             :name=>'cloud-crowd-server', :task=>'crowd:server',
             :enviroment=>node[:documentcloud][:rails_env]
           })
  notifies :enable, "service[documentcloud-crowd-server-node]"
  notifies :start, "service[documentcloud-crowd-server-node]"
end

service "documentcloud-crowd-server-node" do
  priority 85
  supports :restart => true, :start => true, :stop => true
  action :nothing
end
