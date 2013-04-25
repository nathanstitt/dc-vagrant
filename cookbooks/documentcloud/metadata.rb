maintainer       "Nathan Stitt"
maintainer_email "nathan@stitt.org"
license          "MIT"
description      "Configures document cloud"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.5"

supports "debian"
supports "ubuntu"

recipe "documentcloud", "Installs a documentcloud instance"

%w{ hostname apt git postgresql ssh_known_hosts user rake }.each do |cb|
  depends cb
end
