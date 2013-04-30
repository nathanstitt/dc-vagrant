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
* The IP address, login/password, and many other settings may be modified by editing the chef.json area of the Vagrantfile.


### Encryption

The DocumentCloud application requires a ssl connection.

As part of the provisioning process, a self-signed certificate for https://dev.dcloud.org/ is installed.

Because the certificate is self-signed, you will receive a warning in your browser when you load the website.

Depending on which web-browser you are using, you may be able to trust the certificate and proceed.  

Adam Haeder has a comprehensive video on how Windows users can enable Chrome, Firefox, and Internet Explorer
to trust a self signed certificate: http://www.youtube.com/watch?v=2P0bJDKQHpc

If you are on a Mac, loading the certificate into the OSX keychain will also silence the warning message.  
You can do so by using the Chrome web-browser and following these steps *([thanks to Rob Peck](http://www.robpeck.com/blog/2010/10/05/google-chrome-mac-os-x-and-self-signed-ssl-certificates/))*:
* In the address bar, click the little lock with the X. This will bring up a small information screen. Click the button that says “Certificate Information.”
* Click and drag the image to your desktop. It looks like a little certificate.
* Double-click it. This will bring up the Keychain Access utility. Enter your password to unlock it.
* Be sure you add the certificate to the System keychain, not the login keychain. Click “Always Trust,” even though this doesn’t seem to do anything.
* After it has been added, double-click it. You may have to authenticate again.
* Expand the “Trust” section.
* “When using this certificate,” set to “Always Trust”


