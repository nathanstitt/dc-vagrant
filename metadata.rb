name             'documentcloud'
maintainer       'YOUR_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures documentcloud'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

%w{ hostname apt git postgresql ssh_known_hosts user sudo ruby_install chruby rake }.each do |cb|
  depends cb
end
