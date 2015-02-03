#!/bin/sh
# -------
# Script for maintenance shutdown of Alfresco
# 
# Copyright 2015, Kristoffer Andergrim
# Based on alfresco-ubuntu-install by Peter Löfgren, Loftux AB
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------

USER="www"
ALF_HOME_WWW="/opt/alfresco/www"
DOWNTIME="10"

((!$#)) && echo Supply expected downtime in minutes as argument! && exit 1

die () {
    echo >&2 "$@"
    exit 1
}

if [ "$#" -gt 0 ]; then
   echo $1 | grep -E -q '^[0-9]+$' || die "Numeric argument required, $1 provided"
   DOWNTIME=$1
fi

echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Updating maintenance message script file"
echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo
su -m www -c "touch ${ALF_HOME_WWW}/downtime.js"
echo "var downTime = ${DOWNTIME};" | tee  ${ALF_HOME_WWW}/downtime.js
echo "var startTime = `date +%s`;" | tee -a ${ALF_HOME_WWW}/downtime.js
echo "var specialMessage = '$2';" | tee -a ${ALF_HOME_WWW}/downtime.js
echo
echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Stopping the Alfresco tomcat instance"
echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo
service alfresco stop