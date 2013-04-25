install_dir = Pathname.new node[:documentcloud][:directory]

template "#{node['postgresql']['dir']}/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  group "postgres"
  mode 00600
  notifies :reload, 'service[postgresql]', :immediately
end

ruby_block 'configure' do

  notifies :create, "template[#{node['postgresql']['dir']}/pg_hba.conf]", :immediately

  block do
    require 'erb'
    require 'yaml'
    class Rails;   def self.root;  @@root;  end    end
    Rails.send :class_variable_set, :@@root, install_dir
    config = YAML.load( ERB.new(File.read( install_dir.join('config','database.yml') ) ).result(binding) )[ node.documentcloud.rails_env ]

#    STDERR.puts config.to_yaml

    bash = Chef::Resource::Script::Bash.new('create-db-account',run_context)
    bash.user 'postgres'
    code =  "createuser --no-createrole --no-superuser --no-createdb #{config['username']}\n"
    node['dbname'] = config['database']

    node['postgresql']['pg_hba'] << {
      :type => 'local', :db => config['database'], :user => config['username'], :addr => nil, :method => 'trust'
    }

    if config['password']
      code << "psql -c \"ALTER USER #{config['username']} WITH PASSWORD '#{config['password']}'\""
    end
    bash.code code
    bash.not_if  "psql -c \"\\du\" | grep #{config['username']}"
    bash.run_action(:run)

    bash = Chef::Resource::Script::Bash.new('create-database',run_context)
    bash.user 'postgres'
    bash.cwd install_dir.to_s
    bash.code <<-EOS
      createdb -O #{config['username']} #{config['database']}
      psql #{config['database']} < db/development_structure.sql
      tables=`psql -qAt -c "select tablename from pg_tables where schemaname = 'public';" #{config['database']}`
      for tbl in $tables ; do
        psql -c "alter table $tbl owner to #{config['username']}" #{config['database']};
      done

    EOS
    bash.not_if "psql -l | grep -c #{config['database']}"
    bash.run_action(:run)

  end
end
