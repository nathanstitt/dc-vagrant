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
    Dir.chdir "#{install_dir.to_s}"
    class Rails;   def self.root;  @@root;  end    end
    Rails.send :class_variable_set, :@@root, install_dir
    db = YAML.load(
      ERB.new(File.read( install_dir.join('config','database.yml') ) ).result(binding)
      )[ node.documentcloud.rails_env ]

    analytics = YAML.load(
      ERB.new(File.read( install_dir.join('config','database_analytics.yml') ) ).result(binding)
      )[ node.documentcloud.rails_env ]

    bash = Chef::Resource::Script::Bash.new('create-db-account',run_context)
    bash.user 'postgres'
    code =  "createuser --no-createrole --no-superuser --no-createdb #{db['username']}\n"

    node['postgresql']['pg_hba'] << {
      :type => 'local', :db => db['database'], :user => db['username'], :addr => nil, :method => 'trust'
    }

    if db['password']
      code << "psql -c \"ALTER USER #{db['username']} WITH PASSWORD '#{db['password']}'\""
    end
    bash.code code
    bash.not_if  "psql -c \"\\du\" | grep #{db['username']}"
    bash.run_action(:run)

    if analytics['username'] != db['username']
      bash = Chef::Resource::Script::Bash.new('create-db-account',run_context)
      bash.user 'postgres'
      code =  "createuser --no-createrole --no-superuser --no-createdb #{analytics['username']}\n"
      if analytics['password']
        code << "psql -c \"ALTER USER #{analytics['username']} WITH PASSWORD '#{analytics['password']}'\""
      end
      bash.code code
      bash.not_if  "psql -c \"\\du\" | grep #{analytics['username']}"
      bash.run_action(:run)
    end

    bash = Chef::Resource::Script::Bash.new('create-database',run_context)
    bash.user 'postgres'
    bash.cwd install_dir.to_s
    bash.code <<-EOS
      createdb  --template=template0 --locale=en_US.utf8 --encoding=UTF8 --owner=#{db['username']} #{db['database']}
      psql #{db['database']} -c 'create extension if not exists hstore'
      psql #{db['database']} < db/development_structure.sql
      tables=`psql -qAt -c "select tablename from pg_tables where schemaname = 'public';" #{db['database']}`
      for tbl in $tables ; do
        psql -c "alter table $tbl owner to #{db['username']}" #{db['database']};
      done
    EOS
    bash.not_if "psql -l | grep #{db['database']}"
    bash.run_action(:run)

    bash = Chef::Resource::Script::Bash.new('create-analytics-database',run_context)
    bash.user 'postgres'
    bash.cwd install_dir.to_s
    bash.code <<-EOS
      createdb  --template=template0 --locale=en_US.utf8 --encoding=UTF8 --owner=#{analytics['username']} #{analytics['database']}
      psql #{analytics['database']} < db/analytics_structure.sql
      tables=`psql -qAt -c "select tablename from pg_tables where schemaname = 'public';" #{analytics['database']}`
      for tbl in $tables ; do
        psql -c "alter table $tbl owner to #{analytics['username']}" #{analytics['database']};
      done
    EOS
    bash.not_if "psql -l | grep #{analytics['database']}"
    bash.run_action(:run)

  end
end
