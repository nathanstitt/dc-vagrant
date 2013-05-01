DocumentCloud Vagrant
=====================

A collection of chef recipes that will configure a Vagrant box into a fully functioning DocumentCloud server.

Basic Instructions
------------

* Download Vagrant version 1.2 or newer from: http://downloads.vagrantup.com/ and then install it.
* Clone this repository
* In the terminal, change directory to where the repository was cloned.
* Start the provisioning process by typing: ```vagrant up``` and then pressing enter.
  * After doing so, you'll see quite a few status messages scroll by on the screen.
  * This process will take at least 10 minutes and probably quite a bit longer depending on the speed of your computer and internet connection.
* Once the provisioning process completes, you should be able to load your new DocumentCloud virtual machine at http://192.168.33.10/
* The default login for the website is: ```testing@documentcloud.org``` and password: ```testingpw```
* You can access the shell on the virtual machine using ssh by executing: ```vagrant ssh```


Encryption
------------

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

Advanced Configuration
-----------------------

If a config.yml file is present in the same directory as the Vagrantfile, configuration will be read from it.
See the config.yml.sample file for a sample configuration.

Using synced_folders for development
----------------------------------

The easiest way to modify the documentcloud source is by using Vagrant's synced_folders feature.

To do so, first make sure you can provision a complete DocumentCloud server by performing: ```vagrant up```

Once that completes, shutdown your virtual machine with: ```vagrant halt```

Checkout a copy of the DocumentCloud source to a local directory where you want to work on it from either from https://github.com/documentcloud/documentcloud or from your own fork of it.

Create or edit the config.yml file by using the config.yml.sample as a template.

Setup the sync_folders section.

* The host setting should point to the path to the directory where you checked out the source.  Relative or absolute paths are acceptable.
* The guest setting refers to the path inside the virtual machine where the documentcloud source resides.  By default this is: /hom/dcloud/documentcloud
* The options -> owner setting must be set to same as the account/login.  It defaults to: ```dcloud```

Restart vagrant with: ```vagrant up```

You should now be able to modify files in your local documentcloud directory and see the changes picked up immediatly by the application
