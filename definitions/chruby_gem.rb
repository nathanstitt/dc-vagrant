define :chruby_gem, :action => :install do
  version = params[:ruby] || node[:chruby][:default]
  gem_package "chruby #{version}: #{params[:name]}" do
    package_name params[:name]
    gem_binary "/opt/rubies/ruby-#{version}/bin/gem"
    version params[:version] if params[:version]
    action params[:action]
  end
end
