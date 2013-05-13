ssh_known_hosts_entry 'github.com'

# Variables from config
install_dir = Pathname.new node[:documentcloud][:directory]
user_id     = node[:account][:login]

include_recipe 'documentcloud::base'

directory '/etc/cloud_crowd' do
  mode 0755
end

directory install_dir.join('tmp','pids',node.host_name).to_s do
  owner user_id
  group user_id
  mode 0777
end

directory install_dir.join('log',node.host_name).to_s do
  owner user_id
  group user_id
  mode 0777
end

template '/etc/cloud_crowd/config.yml' do
  source 'cloud_crowd_node_config.yml.erb'
  mode   '0664'
end

template '/etc/cloud_crowd/config.ru' do
  source 'cloud_crowd.ru.erb'
  mode   '0664'
end

template '/etc/cloud_crowd/database.yml' do
  source 'cloud_crowd_database.yml.erb'
  mode   '0664'
end


bash 'cloud-crowd-node' do
  user user_id
  cwd install_dir.to_s
  code <<-EOS
     pkill -f cloud-crowd-node
     crowd -c /etc/cloud_crowd -e #{node.documentcloud.rails_env} node -d start
  EOS
end
