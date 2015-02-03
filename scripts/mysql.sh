#!/bin/sh
# -------
# Script for install of MySQL to be used with Alfresco
# 
# Copyright 2015, Kristoffer Andergrim
# Based on alfresco-ubuntu-install by Peter Löfgren, Loftux AB
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------

export ALFRESCODB=alfresco
export ALFRESCOUSER=alfresco

echo
echo "--------------------------------------------"
echo "This script will install MySQL database server"
echo "and create alfresco database and user."
echo "This script should be run as root."
echo "--------------------------------------------"
echo

read -e -p "Install MySQL database server? [y/N] " INSTALLMYSQL
if [ "$INSTALLMYSQL" = "y" ]; then
  pkg install -y mysql55-server

  echo Adding rc.conf knob setting
  MYRC=`cat /etc/rc.conf | grep 'mysql_enable="YES"' |wc -l`
  if [ "$MYRC" -eq "0" ]; then
    printf '\nmysql_enable="YES"\n' >> /etc/rc.conf
  fi

  service mysql-server start

fi

read -e -p "Create Alfresco database and user? [y/N] " CREATEDB
if [ "$CREATEDB" = "y" ]; then
  read -e -p "Enter a new password for database user $ALFRESCOUSER: " ALFRESCOPASSWORD
  read -e -p "Re-enter the password: " ALFRESCOPASSWORD2
  if [ "$ALFRESCOPASSWORD" == "$ALFRESCOPASSWORD2" ]; then
    echo "Creating Alfresco database ($ALFRESCODB) and user ($ALFRESCOUSER)."
    echo "To add new database and user you need to enter the MySQL root password"
    mysql -u root -p << EOF
CREATE DATABASE $ALFRESCODB default character set utf8 collate utf8_bin;
GRANT all on $ALFRESCODB.* to '$ALFRESCOUSER'@'localhost' identified by '$ALFRESCOPASSWORD' with grant option;
GRANT all on $ALFRESCODB.* to '$ALFRESCOUSER'@'%' identified by '$ALFRESCOPASSWORD' with grant option;
FLUSH PRIVILEGES;
EOF
    echo
    echo "Remember to update alfresco-global.properties with the alfresco database password"
    echo
  else
    echo
    echo "Passwords do not match. Please run the script again for better luck!"
    echo
  fi
fi
