#!/bin/sh
# -------
# Script for install of Alfresco
#
# Copyright 2015, Kristoffer Andergrim
# Based on alfresco-ubuntu-install by Peter Löfgren, Loftux AB
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------

export ALF_HOME=/opt/alfresco
export ALF_DATA_HOME=$ALF_HOME/alf_data
export CATALINA_HOME=$ALF_HOME/tomcat
export ALF_USER=alfresco
export ALF_GROUP=www
export TMP_INSTALL=/tmp/alfrescoinstall

export BASE_DOWNLOAD=https://raw.githubusercontent.com/andergrim/alfresco-freebsd-install/master
export KEYSTOREBASE=https://svn.alfresco.com/repos/alfresco-open-mirror/alfresco/HEAD/root/projects/repository/config/alfresco/keystore

#Change this to prefered locale to make sure it exists. This has impact on LibreOffice transformations
#export LOCALESUPPORT=sv_SE.UTF-8
export LOCALESUPPORT=en_US.UTF-8

export JDBCMYSQLURL=http://cdn.mysql.com/Downloads/Connector-J
export JDBCMYSQL=mysql-connector-java-5.1.36.tar.gz

export LIBREOFFICE=http://downloadarchive.documentfoundation.org/libreoffice/old/4.4.5.1/deb/x86_64/LibreOffice_4.4.5.1_Linux_x86-64_deb.tar.gz
export SWFTOOLS=http://www.swftools.org/swftools-2013-04-09-1007.tar.gz

export ALFREPOWAR=https://artifacts.alfresco.com/nexus/service/local/repo_groups/public/content/org/alfresco/alfresco/5.0.d/alfresco-5.0.d.war
export ALFSHAREWAR=https://artifacts.alfresco.com/nexus/service/local/repo_groups/public/content/org/alfresco/share/5.0.d/share-5.0.d.war
export GOOGLEDOCSREPO=https://artifacts.alfresco.com/nexus/service/local/repo_groups/public/content/org/alfresco/integrations/alfresco-googledocs-repo/3.0.2/alfresco-googledocs-repo-3.0.2.amp
export GOOGLEDOCSSHARE=https://artifacts.alfresco.com/nexus/service/local/repo_groups/public/content/org/alfresco/integrations/alfresco-googledocs-share/3.0.2/alfresco-googledocs-share-3.0.2.amp
export SPP=https://artifacts.alfresco.com/nexus/service/local/repo_groups/public/content/org/alfresco/alfresco-spp/5.0.d/alfresco-spp-5.0.d.amp

export SOLR4_CONFIG_DOWNLOAD=https://artifacts.alfresco.com/nexus/service/local/repo_groups/public/content/org/alfresco/alfresco-solr4/5.0.d/alfresco-solr4-5.0.d-config-ssl.zip
export SOLR4_WAR_DOWNLOAD=https://artifacts.alfresco.com/nexus/service/local/repo_groups/public/content/org/alfresco/alfresco-solr4/5.0.d/alfresco-solr4-5.0.d-ssl.war

echoblue () {
  printf '\033[1;34;40m'
  echo $1
  printf '\033[0m'
}
echored () {
  printf '\033[1;31;40m'
  echo $1
  printf '\033[0m'
}
echogreen () {
  printf '\033[1;32;40m'
  echo $1
  printf '\033[0m'
}

# Create temp directory
cd /tmp
if [ -d "alfrescoinstall" ]; then
	rm -rf alfrescoinstall
fi
mkdir alfrescoinstall
cd ./alfrescoinstall

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Alfresco FreeBSD installer"
echogreen "Please read the documentation at"
echogreen "https://github.com/andergrim/alfresco-freebsd-install."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Checking for the availability of the URLs inside script..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

if [ "`which curl`" = "" ]; then
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You need to install curl. Curl is used for downloading components to install."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  pkg install -y curl > /dev/null;
fi

URLERROR=0

for REMOTE in $JDBCMYSQLURL/$JDBCMYSQL $LIBREOFFICE $SWFTOOLS $ALFWARZIP $GOOGLEDOCSREPO \
              $GOOGLEDOCSSHARE $SOLR4_CONFIG_DOWNLOAD $SOLR4_WAR_DOWNLOAD $SPP
  do
    OUTPUT=`curl --write-out %{http_code} --silent --head --output /dev/null $REMOTE`
    if [ $OUTPUT != 200 ]
      then
        echored "In alfinstall.sh, please fix this URL: $REMOTE"
        URLERROR=1
    fi
done



if [ $URLERROR = 1 ]
  then
    echo
    echored "Please fix the above errors and rerun."
    echo
    exit 1
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Preparing for install. Updating the FreeBSD repository catalogue..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
pkg update;
echo

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "You need to add a system user that runs the tomcat Alfresco instance."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add alfresco system user [y/N] " addalfresco
if [ "$addalfresco" = "y" ]; then
  pw adduser $ALF_USER -g $ALF_GROUP -d /nonexistent -s /usr/sbin/nologin -w no
  echo
  echogreen "Finished adding alfresco user"
  echo
else
  echo "Skipping adding alfresco user"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Tomcat is the application server that runs Alfresco."
echo "You will also get the option to install jdbc lib for Postgresql or MySql/MariaDB."
echo "Install the jdbc lib for the database you intend to use."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Tomcat [y/N] " INSTALLTOMCAT

if [ "$INSTALLTOMCAT" = "y" ]; then
  echogreen "Installing Tomcat"
  pkg install -y tomcat7 > /dev/null
 
  # Make sure install dir exists, then create symbolic link
  mkdir -p $ALF_HOME
  ln -s /usr/local/apache-tomcat-7.0 $CATALINA_HOME

  # Remove apps not needed
  rm -rf $CATALINA_HOME/webapps/*
  # Get Alfresco config

  ALFRC=`cat /etc/rc.conf | grep 'alfresco_enable="YES"' |wc -l`
  if [ "$ALFRC" -eq "0" ]; then
    printf '\nalfresco_enable="YES"\n' >> /etc/rc.conf
  fi

  echo "Downloading tomcat configuration files..."
  curl -# -o $CATALINA_HOME/conf/server.xml $BASE_DOWNLOAD/tomcat/server.xml
  curl -# -o $CATALINA_HOME/conf/catalina.properties $BASE_DOWNLOAD/tomcat/catalina.properties
  curl -# -o $CATALINA_HOME/conf/tomcat-users.xml $BASE_DOWNLOAD/tomcat/tomcat-users.xml

  curl -# -o /usr/local/etc/rc.d/alfresco $BASE_DOWNLOAD/tomcat/alfresco
  chmod +x /usr/local/etc/rc.d/alfresco
  sed -i '' "s/@@LOCALESUPPORT@@/$LOCALESUPPORT/g" /usr/local/etc/rc.d/alfresco

  # Create /shared
  mkdir -p $CATALINA_HOME/shared/classes/alfresco/extension
  mkdir -p $CATALINA_HOME/shared/classes/alfresco/web-extension
  mkdir -p $CATALINA_HOME/shared/lib
  # Add endorsed dir
  mkdir -p $CATALINA_HOME/endorsed
  echo
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You need to add the dns name, port and protocol for your server(s)."
  echo "It is important that this is is a resolvable server name."
  echo "This information will be added to default configuration files."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  
  read -e -p "Please enter the public host name for Share server (fully qualified domain name) [`hostname`] " GET_SHARE_HOSTNAME
  if [ "$GET_SHARE_HOSTNAME" = "" ]; then
    SHARE_HOSTNAME=`hostname`
  else
    SHARE_HOSTNAME=$GET_SHARE_HOSTNAME
  fi

  read -e -p "Please enter the protocol to use for public Share server (http or https) [http] " SHARE_PROTOCOL
  if [ "$SHARE_PROTOCOL" = "https" ]; then
    SHARE_PORT=443
  else
    SHARE_PORT=80
    SHARE_PROTOCOL="http"
  fi
  
  read -e -p "Please enter the host name for Alfresco Repository server (fully qualified domain name) [$SHARE_HOSTNAME] " GET_REPO_HOSTNAME
  if [ "$GET_REPO_HOSTNAME" = "" ]; then
    REPO_HOSTNAME=$SHARE_HOSTNAME
  else
    REPO_HOSTNAME=$GET_REPO_HOSTNAME
  fi

  # Add default alfresco-global.propertis
  ALFRESCO_GLOBAL_PROPERTIES=/tmp/alfrescoinstall/alfresco-global.properties
  curl -# -o $ALFRESCO_GLOBAL_PROPERTIES $BASE_DOWNLOAD/tomcat/alfresco-global.properties
  sed -i '' "s/@@ALFRESCO_SHARE_SERVER@@/$SHARE_HOSTNAME/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i '' "s/@@ALFRESCO_SHARE_SERVER_PORT@@/$SHARE_PORT/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i '' "s/@@ALFRESCO_SHARE_SERVER_PROTOCOL@@/$SHARE_PROTOCOL/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i '' "s/@@ALFRESCO_REPO_SERVER@@/$REPO_HOSTNAME/g" $ALFRESCO_GLOBAL_PROPERTIES
  mv $ALFRESCO_GLOBAL_PROPERTIES $CATALINA_HOME/shared/classes/

  read -e -p "Install Share config file (recommended) [y/N] " INSTALLSHARECONFIG
  if [ "$INSTALLSHARECONFIG" = "y" ]; then
    SHARE_CONFIG_CUSTOM=/tmp/alfrescoinstall/share-config-custom.xml
    curl -# -o $SHARE_CONFIG_CUSTOM $BASE_DOWNLOAD/tomcat/share-config-custom.xml
    sed -i '' "s/@@ALFRESCO_SHARE_SERVER@@/$SHARE_HOSTNAME/g" $SHARE_CONFIG_CUSTOM
    sed -i '' "s/@@ALFRESCO_REPO_SERVER@@/$REPO_HOSTNAME/g" $SHARE_CONFIG_CUSTOM
    mv $SHARE_CONFIG_CUSTOM $CATALINA_HOME/shared/classes/alfresco/web-extension/
  fi

  echo
  read -e -p "Install Postgres JDBC Connector [y/N] " INSTALLPG
  if [ "$INSTALLPG" = "y" ]; then
	  pkg install -y postgresql-jdbc-9.2.1004 > /dev/null
	  cp /usr/local/share/java/classes/postgresql.jar $CATALINA_HOME/lib
  fi
  echo
  read -e -p "Install Mysql JDBC Connector [y/N] " INSTALLMY
  if [ "$INSTALLMY" = "y" ]; then
    cd /tmp/alfrescoinstall
	  curl -# -L -O $JDBCMYSQLURL/$JDBCMYSQL
	  tar xf $JDBCMYSQL
	  cd "$(find . -type d -name "mysql-connector*")"
	  mv mysql-connector*.jar $CATALINA_HOME/lib
  fi

  chown -LR $ALF_USER:$ALF_GROUP $CATALINA_HOME
  echo
  echogreen "Finished installing Tomcat"
  echo
else
  echo "Skipping install of Tomcat"
  echo
fi


echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Nginx can be used as frontend to Tomcat."
echo "This installation will add config default proxying to Alfresco tomcat."
echo "The config file also have sample config for ssl and proxying"
echo "to Sharepoint plugin."
echo "You can run Alfresco fine without installing nginx."
echo "If you prefer to use Apache httpd or lighttpd, install that manually."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install nginx [y/N] " INSTALLNGINX
if [ "$INSTALLNGINX" = "y" ]; then
  echoblue "Installing nginx..."
  echo
  pkg install -y nginx-devel > /dev/null
  mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.backup
  curl -# -o /usr/local/etc/nginx/nginx.conf $BASE_DOWNLOAD/nginx/nginx.conf
  mkdir -p /var/cache/nginx/alfresco
  mkdir -p $ALF_HOME/www
  if [ ! -f "$ALF_HOME/www/maintenance.html" ]; then
    echo "Downloading maintenance html page..."
    curl -# -o $ALF_HOME/www/maintenance.html $BASE_DOWNLOAD/nginx/maintenance.html
  fi
  chown -R www:wheel /var/cache/nginx/alfresco
  chown -R www:wheel $ALF_HOME/www
  touch /var/log/nginx-error.log
  chown www:www /var/log/nginx-error.log

  # Start service
  echo 
  echo "Starting nginx service..."
  
  NGINXRC=`cat /etc/rc.conf | grep 'nginx_enable="YES"' |wc -l`
  if [ "$NGINXRC" -eq "0" ]; then
    printf '\nnginx_enable="YES"\n' >> /etc/rc.conf
  fi
  service nginx start

  echo
  echogreen "Finished installing nginx"
  echo
else
  echo "Skipping install of nginx"
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Java JDK."
echo "This will install the OpenJDK version of Java. If you prefer Oracle Java"
echo "you need to download and install that manually (see README.md for more info)."
echo "If you have installed Tomcat previously OpenJDK is most likely already installed."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install OpenJDK7 [y/N] " INSTALLJDK
if [ "$INSTALLJDK" = "y" ]; then
  echoblue "Installing OpenJDK7..."
  pkg install -y openjdk
  echo
  echogreen "Finished installing OpenJDK"
  echo
else
  echo "Skipping install of OpenJDK 7"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install LibreOffice."
echo "This will download and install the latest LibreOffice from libreoffice.org"
echo "Newer version of Libreoffice has better document filters, and produce better"
echo "transformations."
echo "Installing LibreOffice will also install X11. If you don't want X11 on your system"
echo "you should skip this step."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install LibreOffice [y/N] " INSTALLIBREOFFICE
if [ "$INSTALLIBREOFFICE" = "y" ]; then
  echoblue "Installing LibreOffice..."
  pkg install -y libreoffice > /dev/null
  echo
  echoblue "Installing some support fonts for better transformations."
  pkg install -y liberation-fonts-ttf droid-fonts-ttf > /dev/null
  echo
  echogreen "Finished installing LibreOffice"
  echo
else
  echo
  echo "Skipping install of LibreOffice"
  echored "If you install LibreOffice/OpenOffice separetely, remember to update alfresco-global.properties"
  echored "Also run: pkg install liberation-fonts-ttf droid-fonts-ttf"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install ImageMagick."
echo "This will ImageMagick (No X11) from FreeBSD package repositories."
echo "It is recommended that you install ImageMagick."
echo "If you prefer some other way of installing ImageMagick, skip this step."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install ImageMagick [y/N] " INSTALLIMAGEMAGICK
if [ "$INSTALLIMAGEMAGICK" = "y" ]; then
  echoblue "Installing ImageMagick..."
  pkg install -y ImageMagick-nox11 > /dev/null
  echo
  echogreen "Finished installing ImageMagick"
  echo
else
  echo
  echo "Skipping install of ImageMagick"
  echored "Remember to install ImageMagick later. It is needed for thumbnail transformations."
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install swftools."
echo "This will download and install swftools used for transformations to Flash."
echo "Installing swftools will also install X11. If you don't want X11 on your system"
echo "you should skip this step."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install swftools [y/N] " INSTALLSWFTOOLS

if [ "$INSTALLSWFTOOLS" = "y" ]; then
  echoblue "Installing swftools..."
  pkg install -y swftools > /dev/null
  echo
  echogreen "Finished installing swftools"
  echo
else
  echo
  echo "Skipping install of swftools."
  echored "Remember to install swftools (pdf2swf) later."
  echo
fi

echo
echoblue "Adding basic support files. Always installed if not present."
echo

  # Always add the addons dir and scripts
  mkdir -p $ALF_HOME/addons/war
  mkdir -p $ALF_HOME/addons/share
  mkdir -p $ALF_HOME/addons/alfresco
  if [ ! -f "$ALF_HOME/addons/apply.sh" ]; then
    echo "Downloading apply.sh script..."
    curl -# -o $ALF_HOME/addons/apply.sh $BASE_DOWNLOAD/scripts/apply.sh
    chmod u+x $ALF_HOME/addons/apply.sh
  fi

  if [ ! -f "$ALF_HOME/addons/alfresco-mmt.jar" ]; then
    curl -# -o $ALF_HOME/addons/alfresco-mmt.jar $BASE_DOWNLOAD/scripts/alfresco-mmt.jar
  fi

  mkdir -p $ALF_HOME/scripts
  if [ ! -f "$ALF_HOME/scripts/mariadb.sh" ]; then
    echo "Downloading mariadb.sh install and setup script..."
    curl -# -o $ALF_HOME/scripts/mariadb.sh $BASE_DOWNLOAD/scripts/mariadb.sh
  fi

  if [ ! -f "$ALF_HOME/scripts/postgresql.sh" ]; then
    echo "Downloading postgresql.sh install and setup script..."
    curl -# -o $ALF_HOME/scripts/postgresql.sh $BASE_DOWNLOAD/scripts/postgresql.sh
  fi

  if [ ! -f "$ALF_HOME/scripts/mysql.sh" ]; then
    echo "Downloading mysql.sh install and setup script..."
    curl -# -o $ALF_HOME/scripts/mysql.sh $BASE_DOWNLOAD/scripts/mysql.sh
  fi

  if [ ! -f "$ALF_HOME/scripts/createssl.sh" ]; then
    echo "Downloading createssl.sh script..."
    curl -# -o $ALF_HOME/scripts/createssl.sh $BASE_DOWNLOAD/scripts/createssl.sh
  fi

  if [ ! -f "$ALF_HOME/scripts/libreoffice.sh" ]; then
    echo "Downloading libreoffice.sh script..."
    curl -# -o $ALF_HOME/scripts/libreoffice.sh $BASE_DOWNLOAD/scripts/libreoffice.sh
    sed -i '' "s/@@LOCALESUPPORT@@/$LOCALESUPPORT/g" $ALF_HOME/scripts/libreoffice.sh
  fi

  if [ ! -f "$ALF_HOME/scripts/ams.sh" ]; then
    echo "Downloading maintenance shutdown script..."
    curl -# -o $ALF_HOME/scripts/ams.sh $BASE_DOWNLOAD/scripts/ams.sh
  fi
  chmod u+x $ALF_HOME/scripts/*.sh

  # Keystore
  mkdir -p $ALF_DATA_HOME/keystore
  # Only check for precesence of one file, assume all the rest exists as well if so.
  if [ ! -f " $ALF_DATA_HOME/keystore/ssl.keystore" ]; then
    echo "Downloading keystore files..."
    curl -# -o $ALF_DATA_HOME/keystore/browser.p12 $KEYSTOREBASE/browser.p12
    curl -# -o $ALF_DATA_HOME/keystore/generate_keystores.sh $KEYSTOREBASE/generate_keystores.sh
    curl -# -o $ALF_DATA_HOME/keystore/keystore $KEYSTOREBASE/keystore
    curl -# -o $ALF_DATA_HOME/keystore/keystore-passwords.properties $KEYSTOREBASE/keystore-passwords.properties
    curl -# -o $ALF_DATA_HOME/keystore/ssl-keystore-passwords.properties $KEYSTOREBASE/ssl-keystore-passwords.properties
    curl -# -o $ALF_DATA_HOME/keystore/ssl-truststore-passwords.properties $KEYSTOREBASE/ssl-truststore-passwords.properties
    curl -# -o $ALF_DATA_HOME/keystore/ssl.keystore $KEYSTOREBASE/ssl.keystore
    curl -# -o $ALF_DATA_HOME/keystore/ssl.truststore $KEYSTOREBASE/ssl.truststore
  fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Alfresco war files."
echo "Download war files and optional addons."
echo "If you have downloaded your war files you can skip this step and add them manually."
echo "This install will place downloaded files in the $ALF_HOME/addons and then use the"
echo "apply.sh script to add them to tomcat/webapps. Se this script for more info."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add Alfresco war files [y/N] " INSTALLWAR
if [ "$INSTALLWAR" = "y" ]; then

  echogreen "Downloading alfresco and share war files..."
  curl -# -o $ALF_HOME/addons/war/alfresco.war $ALFREPOWAR
  curl -# -o $ALF_HOME/addons/war/share.war $ALFSHAREWAR

  cd /tmp/alfrescoinstall

  read -e -p "Add Google docs integration [y/N] " INSTALLGOOGLEDOCS
  if [ "$INSTALLGOOGLEDOCS" = "y" ]; then
  	echo "Downloading Google docs addon..."
    curl -# -O $GOOGLEDOCSREPO
    mv alfresco-googledocs-repo*.amp $ALF_HOME/addons/alfresco/
    curl -# -O $GOOGLEDOCSSHARE
    mv alfresco-googledocs-share* $ALF_HOME/addons/share/
  fi

  read -e -p "Add Sharepoint plugin [y/N] " INSTALLSPP
  if [ "$INSTALLSPP" = "y" ]; then
    echo "Downloading Sharepoint addon..."
    curl -# -O $SPP
    mv alfresco-spp*.amp $ALF_HOME/addons/alfresco/
  fi

  $ALF_HOME/addons/apply.sh all

  echo
  echogreen "Finished adding Alfresco war files"
  echo
else
  echo
  echo "Skipping adding Alfresco war files"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Solr4 indexing engine."
echo "You can run Solr4 on a separate server, unless you plan to do that you should"
echo "install the Solr4 indexing engine on the same server as your repository server."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install SOLR4 indexing engine [y/N] " INSTALLSOLR
if [ "$INSTALLSOLR" = "y" ]; then

  # Make sure we have unzip available
  pkg install -y unzip > /dev/null
  
  # Check if we have an old install
  if [ -d "$ALF_HOME/solr4" ]; then
     mv $ALF_HOME/solr4 $ALF_HOME/solr4_BACKUP_`eval date +%Y%m%d%H%M`
  fi
  mkdir -p $ALF_HOME/solr4
  cd $ALF_HOME/solr4

  echogreen "Downloading solr4.war file..."
  curl -# -o $CATALINA_HOME/webapps/solr4.war $SOLR4_WAR_DOWNLOAD

  echogreen "Downloading config file..."
  curl -# -o $ALF_HOME/solr4/solrconfig.zip $SOLR4_CONFIG_DOWNLOAD
  echogreen "Expanding config file..."
  unzip -q solrconfig.zip
  rm solrconfig.zip

  echogreen "Configuring..."

  # Make sure dir exist
  mkdir -p $CATALINA_HOME/conf/Catalina/localhost
  mkdir -p $ALF_DATA_HOME/solr4
  mkdir -p $TMP_INSTALL

  # Remove old config if exists
  if [ -f "$CATALINA_HOME/conf/Catalina/localhost/solr.xml" ]; then
     rm $CATALINA_HOME/conf/Catalina/localhost/solr.xml
  fi

  # Set the solr data path
  SOLRDATAPATH="$ALF_DATA_HOME/solr4"
  
  mv $ALF_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties $ALF_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties.orig
  mv $ALF_HOME/solr4/archive-SpacesStore/conf/solrcore.properties $ALF_HOME/solr4/archive-SpacesStore/conf/solrcore.properties.orig
  sed "s|@@ALFRESCO_SOLR4_DATA_DIR@@|$SOLRDATAPATH|g" $ALF_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties.orig >  $TMP_INSTALL/solrcore.properties
  mv $TMP_INSTALL/solrcore.properties $ALF_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties
  sed "s|@@ALFRESCO_SOLR4_DATA_DIR@@|$SOLRDATAPATH|g" $ALF_HOME/solr4/archive-SpacesStore/conf/solrcore.properties.orig >  $TMP_INSTALL/solrcore.properties
  mv $TMP_INSTALL/solrcore.properties $ALF_HOME/solr4/archive-SpacesStore/conf/solrcore.properties

  echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > $TMP_INSTALL/solr4.xml
  echo "<Context debug=\"0\" crossContext=\"true\">" >> $TMP_INSTALL/solr4.xml
  echo "  <Environment name=\"solr/home\" type=\"java.lang.String\" value=\"$ALF_HOME/solr4\" override=\"true\"/>" >> $TMP_INSTALL/solr4.xml
  echo "  <Environment name=\"solr/model/dir\" type=\"java.lang.String\" value=\"$ALF_HOME/solr4/alfrescoModels\" override=\"true\"/>" >> $TMP_INSTALL/solr4.xml
  echo "  <Environment name=\"solr/content/dir\" type=\"java.lang.String\" value=\"$ALF_DATA_HOME/solr4\" override=\"true\"/>" >> $TMP_INSTALL/solr4.xml
  echo "</Context>" >> $TMP_INSTALL/solr4.xml
  mv $TMP_INSTALL/solr4.xml $CATALINA_HOME/conf/Catalina/localhost/solr4.xml

  echogreen "Setting permissions..."
  chown -R $ALF_USER:$ALF_GROUP $CATALINA_HOME/webapps
  chown -R $ALF_USER:$ALF_GROUP $ALF_DATA_HOME/solr4
  chown -R $ALF_USER:$ALF_GROUP $ALF_HOME/solr4

  echo
  echogreen "Finished installing Solr4 engine."
  echored "Verify your setting in alfresco-global.properties."
  echo "Set property value index.subsystem.name=solr4"
  echo
else
  echo
  echo "Skipping installing Solr4."
  echo "You can always install Solr4 at a later time."
  echo
fi

# Finally, set the permissions
chown -LR $ALF_USER:$ALF_GROUP $ALF_HOME
if [ -d "$ALF_HOME/www" ]; then
    chown -R www:wheel $ALF_HOME/www
fi

echo
echogreen "- - - - - - - - - - - - - - - - -"
echo "Scripted install complete"
echored "Manual tasks remaining:"
echo "1. Install a database server. Install scripts available in $ALF_HOME/scripts"
echored "   It is however recommended that you use a separate database server."
echo "2. Verify Tomcat memory and locale settings in /usr/local/etc/rc.d/alfresco"
echo "   Alfresco runs best with lots of memory. Add some more to \"lots\" and you will be fine!"
echo "   Match the locale LC_ALL (or remove) setting to the one used in this script."
echo "   Locale setting is needed for LibreOffice date handling support."
echo "3. Update database and other settings in alfresco-global.properties"
echo "   You will find this file in $CATALINA_HOME/shared/classes"
echo "4. Start nginx if you have installed it: service nginx start"
echo "5. Start Alfresco/tomcat: service alfresco start"
echo
