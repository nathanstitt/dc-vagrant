action :run do
  execute "rake" do
    user new_resource.user if new_resource.user
    cwd new_resource.working_directory
    command "bundle exec rake #{new_resource.arguments}"
  end
end
