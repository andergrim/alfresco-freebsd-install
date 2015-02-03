#!/bin/sh
# -------
# Script for install of Postgresql to be used with Alfresco
#
# Copyright 2015, Kristoffer Andergrim
# Based on alfresco-ubuntu-install by Peter Löfgren, Loftux AB
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------

export ALFRESCODB=alfresco
export ALFRESCOUSER=alfresco

echo
echo "--------------------------------------------"
echo "This script will install PostgreSQL."
echo "and create alfresco database and user."
echo "This script should be run as root."
echo "--------------------------------------------"
echo

read -e -p "Install PostgreSQL database? [y/N] " INSTALLPG
if [ "$INSTALLPG" = "y" ]; then
  echo Installing PostgreSQL ...
  pkg install -y postgresql93-server postgresql93-client > /dev/null
  
  echo Adding rc.conf knob setting and initiating system DB ...
  PGRC=`cat /etc/rc.conf | grep 'postgresql_enable="YES"' |wc -l`
  if [ "$PGRC" -eq "0" ]; then
    printf '\npostgresql_enable="YES"\n' >> /etc/rc.conf
  fi

  /usr/local/etc/rc.d/postgresql initdb


  echo
  read -e -p "Configure PostgreSQL for listening to remote connections? [y/N] " CONFIGHOST
  if [ "$CONFIGHOST" = "y" ]; then
    echo Editing configuration files ...
    PGCONFIG="/usr/local/pgsql/data/postgresql.conf"
    awk '/listen_addresses/{print;print "listen_addresses = '"'"'*'"'"'";next}1' $PGCONFIG > $PGCONFIG.tmp && mv $PGCONFIG.tmp $PGCONFIG
  
    echo
    echo "Enter an ip address and netmask to allow remote connections from, in this form: 192.168.0.1/24"
    read -e -p "Just press enter to skip this step (you need to add it manually later): " CONFIGIP

    if [ "$CONFIGIP" = "" ]; then
      echo "Skipping Client Authentication configuration. See the information at the end of this"
      echo "script on how to do this manually."
    else
      printf "\n\nhost\tall\tall\t$CONFIGIP\tmd5\n" >> /usr/local/pgsql/data/pg_hba.conf
    fi
  fi

  echo
  echo "Starting postgresql service ..."
  service postgresql start

  if [ "$?" -gt "0" ]; then
    echo
    echo "Could not start postgresql. Examine output of the attempt above, or consult the "
    echo "logs for information on how to resolve this."
    echo "PostgreSQL setup aborted!"
    exit 1
  fi

  read -e -p "Create Alfresco Database and user? [y/N] " CREATEDB
  
  if [ "$CREATEDB" = "y" ]; then
    echo "Creating PostgreSQL superuser postgres. You will now be prompted for a password."
    echo "Make sure you don't lose it."
    su pgsql -c "createuser -sdrP postgres"

    echo
    echo "Creating the PostgreSQL Alfresco user $ALFRESCOUSER. The password you chose here goes into the"
    echo "alfresco-global.properties file"
    su pgsql -c "createuser -D -A -P $ALFRESCOUSER"

    echo
    echo "Creating Alfresco database ..."
    su pgsql -c "createdb -O $ALFRESCOUSER $ALFRESCODB"
  fi

fi

echo
echo "If you didn't configure remote connection listening earlier you need to make the following "
echo "changes to your postgresql configuration:"
echo
echo "Add the following to /usr/local/pgsql/data/pg_hba.conf"
echo "host all all 192.168.0.1/24 md5"
echo "(With the interface address and netmask matching your setup)"
echo
echo "Add the following to /usr/local/pgsql/data/postgresql.conf"
echo "listen_addresses = \"*\""
echo "(Or a comma separated list of ip addresses to listen on)"
echo
echo "After you have updated, restart the postgres server service postgresql restart"
echo "Before starting Alfresco you can test the database setup by running "
echo "The following command: psql -U $ALFRESCOUSER -d $ALFRESCODB"
echo
