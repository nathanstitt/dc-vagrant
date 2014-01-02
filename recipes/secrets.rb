install_dir = Pathname.new node[:documentcloud][:directory]
user_id     = node[:account][:login]


if node[:secrets_yml]
  file "#{install_dir}/secrets/secrets.yml" do
    owner user_id
    mode 0744
    content node[:secrets_yml]
    action :create
  end
end
