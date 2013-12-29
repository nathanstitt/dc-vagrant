include_recipe "documentcloud::base"

DEBS=\
%w{ openjdk-7-jre-headless }
DEBS.each do | pkg |
  package pkg
end

template '/etc/init.d/documentcloud-solr' do
  source 'rake-service.init.erb'
  mode   '0755'
  variables({
             :name=>'solr-search', :task=>'sunspot:solr',
             :enviroment=>node[:documentcloud][:rails_env]
           })
  notifies :enable, "service[documentcloud-solr]"
  notifies :start, "service[documentcloud-solr]"
end

service "documentcloud-solr" do
  priority 85
  supports :restart => true, :start => true, :stop => true
  action :nothing
end
