include_recipe "documentcloud::base"

# Apt packages
DEBS=\
%w{ libreoffice libreoffice-java-common tesseract-ocr openjdk-7-jre-headless }
DEBS.each do | pkg |
  package pkg
end

# Tesseract language packs
%w{ eng deu spa fra chi-sim chi-tra }.each do | language_code |
  package 'tesseract-ocr-' + language_code
end

template '/etc/init.d/documentcloud-crowd-worker-node' do
  source 'rake-service.init.erb'
  mode   '0755'
  variables({
             :name=>'cloud-crowd-node', :task=>'crowd:node',
             :enviroment=>node[:documentcloud][:rails_env]
           })
  notifies :enable, "service[documentcloud-crowd-worker-node]"
  notifies :start,  "service[documentcloud-crowd-worker-node]"
end

service "documentcloud-crowd-worker-node" do
  priority 86
  supports :restart => true, :start => true, :stop => true
  action :nothing
end

