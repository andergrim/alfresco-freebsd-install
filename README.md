Alfresco FreeBSD install
========================
This install script and guide was created by Kristoffer Andergrim. 

It is entirely based on the [alfresco-ubuntu-install](https://github.com/loftuxab/alfresco-ubuntu-install) project, by Peter Löfgren, Loftux AB. 
Please visit [https://loftux.se](https://loftux.se/sv?ref=freebsdinstall "loftux.se") (Swedish) [https://loftux.com](https://loftux.com/en/?ref=freebsdinstall "loftux.com") (English) for more information.  

![FreeBSD + Alfresco](https://raw.githubusercontent.com/andergrim/alfresco-freebsd-install/master/misc/artwork_128.png)

Alfresco script based install for FreeBSD servers.
----------------------------

This script will help you set up an Alfresco server instance with all necessary third party components.  
Some will be installed via FreeBSD pkgs (pkgng is assumed to be bootstrapped and working), some directly downloaded. The script will walk you through the process. In the end, there will be some manual tasks to complete the installation.

Installing
----
To start the install, in the terminal run:

```
curl -O https://raw.githubusercontent.com/andergrim/alfresco-freebsd-install/master/alfinstall.sh  
chmod u+x alfinstall.sh
./alfinstall.sh
```

curl is not available by default in the FreeBSD environment, so you need to install its package before starting the installation.


All install options will be presented with an introduction. They default to 'n' (no), so type y to actually install that component. You need root access to install.  

But please do read all of this README before you go ahead.  
There is also lots of documentation at http://docs.alfresco.com/4.2/index.jsp. To become an Alfresco server Administator, read the 'Administering' section.  

>###Known issues
>Many components have their download url:s point to specific version.
>Whenever a new version comes out, the older version is removed from the download server and this script breaks. I try to update as soon as I find out. This is known to happen with LibreOffice and Tomcat. The script will check if the needed components are available and break if they are not.

More on the components/installation steps.
=======
Once downloaded you can modify (if needed) the script to fit your purpose. Here is a brief explanation if each section.  

Alfresco User
--------
The Alfresco user is the server account used to run tomcat. You should never run tomcat as root, so if you do not already have the alfresco (default in the install script) user, you should add the alfresco user.  

In this part of the install is also an update to make sure a specific locale is supported (default sv_SE.utf8). This is useful for LibreOffice date formatting to work correctly during transformations.  

Tomcat
--------
Tomcat is the java application server used to actually run Alfresco. The script installs the latest version of Tomcat 7, and then updates its configuration files to better support running Alfresco.  
A startup script `/usr/local/etc/rc.d/alfresco` will be added. Edit locale setting (LC_ALL) and the memory settings in this file to match your server.  
About memory, it has default max set to 2G. That is good enough if you have about 5 users. So add more ram (and then some) to your server, update then Xmx setting in the alfresco rc script. Your Alfresco instance will run much smoother.  

You will be presented with the option to add either MySql or Postgresql jdbc libraries. You should probably add at least one of them.

Once the install is complete (the entire script and the manual steps following that), run  
`service alfresco start` to start and `service alfresco stop` to stop tomcat.

Nginx
--------
It is sometimes useful to have a front-end for your Tomcat Alfresco instance. Since Tomcat runs default on port 8080, you can use Nginx as proxy. It is also a lot easier to add ssl support. The default config includes sample configuration for this. Share resource files (anything loaded from /share/res/) is cached in nginx, so it doesn't need to be fetched from tomcat.  

**Caveat:** The upload progress bar in Share will show the upload as complete when the upload from client to nginx is complete, but the upload from nginx to Tomcat Share/Alfresco continues shortly. Usually this is barely noticeable, since server connections speeds are a lot faster than client server connections.

### Maintenance message support
If you are using Nginx as front-end there is a built in fallback to a maintenance page when the Alfresco tomcat instance is stopped. Nginx will detect that tomcat is not responding and show this page. It will display expected downtime and a progress bar.  
To set the the downtime (in minutes) and a custom message, call the ams.sh script found in script folder.
`ams.sh 20 "Custom message displayed in page"`  
The above example will set the downtime to 20 minutes (from when you shut down) and with a custom message. If called without parameters it defaults to 10 minutes. Custom message is optional, but if used you also must set the timeout.  
The script will shut down Alfresco tomcat instance. To start it you must call `sudo start alfresco`.  

The maintenance.html page is found in its default location /opt/alfresco/www and can be customized to your needs.  

If you want to implement this support and already have run the alfinstall.sh script, compare your nginx.conf to what is currently in git/master.

Java JDK
--------
This script installs OpenJDK. You may want to use Oracle Java, but download and install of Oracle Java could not be scripted. More information about installing Oracle Java in FreeBSD is available [here](https://www.freebsd.org/java/install.html).

OpenJDK (as well as bash shell and other components you may or may not use already) required fdesc and proc file systems to be mounted. The following lines should be added to your /etc/fstab 

```
        fdesc   /dev/fd         fdescfs         rw      0       0
        proc    /proc           procfs          rw      0       0
```

LibreOffice
---------
Installed using the FreeBSD default package. It depends on a large number of X11 components which will be installed on your system even if you just want to run a headless transformation daemon. If this is not desired for your system you need to find another solution. If you come up with a good solution you are most welcome to contact me. 

Swftools
---------
Installed using the FreeBSD default package. It depends one some X11 components. Also adds some Truetype fonts for better rendering.

ImageMagick  
---------  
Installed using the FreeBSD default no-x11 package.  

Alfresco
---------
Download and install of Alfresco itself. Or rather, the alfresco.war and share.war and adds them to tomcat/webapps folder. Current version is 5.0.c.
You also have the option to install Google Docs and Sharepoint addons. Skip if you do not intend to use them, you can always add then later.
You can completely skip this step if you intend to use Enterprise version or any other version. See also the special section about the addons directory.

SOLR4
---------
As of Alfresco 5.0 Lucene is no longer supported (it was deprecated some time ago). SOLR4 is more or less a mandatory install in order to have a working Alfresco setup.

Addons - Manage amps and war files.
========
A special directory is created, `/opt/alfresco/addons`. This directory can be used to manage any addons and the core war files.  
* `addons/alfresco` - Alfresco amp files.  
* `addons/share` - Share amp files.  
* `addons/war` - alfresco.war and share.war files goes in here.  
The script `addons/apply.sh`is what you run to install amp files to war files, and then copy the war files to tomcat/webapps. The script has three parameter options  
* amp - just install the amp files to war files.  
* copy - Copy war files to tomcat/webapps.  
* all - Do both of the above. You can only do this if tomcat is **not** running.  

If you didn't install Alfresco war files with the install script you can use this script to manage your war files. If you for example want to use the Enterprise version, download the war files from Alfresco support portal and add them to the /war directory and the run apply.sh. Or you can always add them directly to tomcat/webapps.

Scripts - Supporting scripts
============================
In the directory `/opt/alfresco/scripts` there are some useful scripts installed. Or if you did not run the install script, grab them from github. Here is what they do:  
* `libreoffice.sh` - Start/stop libreoffice manually. Sometimes libreoffice crashes during a transformation, use this script to start it again. Alfresco will re-connect when the server detects libreoffice is running. You can add this to crontab for automatic checks:  
`*/10 * * * * /opt/alfresco/scripts/libreoffice.sh start 2>&1 >> /opt/alfresco/logs/office.log`
`0 2 * * * /opt/alfresco/scripts/libreoffice.sh restart 2>&1 > /opt/alfresco/logs/office.log`  
This will make sure libreoffice is running (if not already started and tomcat is running). Once per night it will also do a complete restart (in case LibreOffice behaves badly).  
* `createssl.sh` - Create self signed certificates, useful for testing purposes. Works well with nginx.  
* `mariadb.sh` - Install the mariadb database server (the MySql alternative). It is recommended that you instead use a dedicated database server. Seriously, do that. And do some database optimizations, out of scope for this install guide.  
* `postgresql.sh` - Same as for MariaDB, but the postgres version.  
* `ams.sh` - To do a maintenance shutdown. For more, see section under nginx.  

Alfresco BART - Backup and Recovery Tool
========================================
Saved for a rainy day.

FAQ  
===
Can this script be used for any version of Alfresco?
---
Yes, see the Addon section. But do know that it uses latest version of many components, and they may not be Alfresco officially supported stack.
Can I modify the scripts?  
---
Yes, you can either download the install script and modify as needed. Or you clone the entire thing at Github and create your own version. If you create/change anything that you think may be useful, please contribute back.
Upgrading - Can I use this to upgrade an existing install?
---
At this time, this is not the intended use. So short answer is no.  
Longer answer is, you can probably grab pieces of the script to upgrade individual components. Or as is recommended when upgrading, test your upgrade on a separate server. So install a new server with fresh install, then grab a copy of your data and do a test upgrade. If this works, switch to this server. Did you make a backup of your data first?
I want Alfresco and Share on separate server, can this script be used?
---
Yes (and is also recommended for best performance), but all components are not needed on both servers. The Alfresco server probably doesn't need nginx, the Share server doesn't need LibreOffice, ImageMagick, Swftools and Solr. The 'Alfresco' install step will download both alfresco.war and share.war if run, just remove the one that doesn't apply from tomcat/webapps and addons/war directory.
The script does not use version x of component z, can you fix this?
---
Probably, but you can also. Just edit the script with the version you want to use, most of the specific links can be found in the beginning of the script.  
Why does the script use the latest versions/not use FreeBSD packages?
---
This combination of packages/downloaded install has been found to work well. But that may not hold true always. If you feel more confident to run a specific version of a component, or want to use a standard FreeBSD package, modify the script. Or skip that part in the install script, and just use this script as an install guide on what needs to be in place for a production server.  


License
===
Copyright 2015, Kristoffer Andergrim
This guide as well as the script is based on the [alfresco-ubuntu-install](https://github.com/loftuxab/alfresco-ubuntu-install) project by Peter Löfgren, Loftux AB 
Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
