DocumentCloud Vagrant
=====================

A collection of chef recipes that will configure a Vagrant box into a fully functioning DocumentCloud server.

Instructions
------------

* Download Vagrant version 1.2 or newer from: http://downloads.vagrantup.com/ and then install it.
* Clone this repository
* In the terminal, change directory to where the repository was cloned.
* Start the provisioning process by typing: ```vagrant up``` and then pressing enter.
  * After doing so, you'll see quite a few status messages scroll by on the screen.
  * This process will take at least 10 minutes and probably quite a bit longer depending on the speed of your computer and internet connection.
* Once the provisioning process completes, you should be able to load your new DocumentCloud virtual machine at http://192.168.33.10/
* The default login is: ```testing@documentcloud.org``` and password: ```testingpw```
* The IP address, login/password, and many other settings may be modified by editing the Vagrantfile in the directory.


### Encryption

The DocumentCloud application requires a ssl connection.

As part of the provisioning process, a self-signed certificate for https://dev.dcloud.org/ is installed.

Because the certificate is self-signed, you will receive a warning in your browser when you load the website.

Depending on which web-browser you are using, you may be able to trust the certificate and proceed.  
If you are on a Mac, loading the certificate into the OSX keychain will also silence the warning message.

