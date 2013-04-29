dc-vagrant
==========

A Vagrant box that will configure a working documentcloud server

Instructions
------------

* Download Vagrant version 1.2 or newer from: http://downloads.vagrantup.com/ and then install it.
* Clone this repository
* In the terminal, change directory to where the repository was cloned.
* start vagrant provisioning process by typing:  **vagrant up** and then pressing enter.
  * After doing so, you'll see quite a bit of green text scroll by on the screen
  * This process will take at least 10 minutes and probably quite a bit more depending on the speed of your computer and internet connection.
* Once the provisioning process completes, you should be able to load your new Document Cloud virtual machine at http://192.168.33.10/
* The IP address and many other settings may be modified by editing the Vagrantfile in the directory.


DocumentCloud requires a ssl connection.  A self-signed certificate for https://dev.dcloud.org/ will be installed for nginx.  Because the certificate is self-signed, you will receive a warning in your browser when you load the website.  Loading the certificate into your keychain on os-x will silence the warning message.
