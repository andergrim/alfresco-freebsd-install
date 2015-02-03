#!/bin/sh
#
# Script for starting/stopping LibreOffice without restarting Alfresco
# 
# Copyright 2015, Kristoffer Andergrim
# Based on alfresco-ubuntu-install by Peter Löfgren, Loftux AB
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------

    # User under which tomcat will run
    USER="alfresco"
    ALF_HOME="/opt/alfresco"
    cd "$ALF_HOME"
    # export LC_ALL else openoffice may use en settings on dates etc
    export LC_ALL=@@LOCALESUPPORT@@
    export CATALINA_PID="${ALF_HOME}/tomcat.pid"

    RETVAL=0

    start() {
        OFFICE_PORT=`ps axww|grep soffice.bin|grep 8100|wc -l`
        if [ "$OFFICE_PORT" -ne "0" ]; then
            CURRENT_PROCID=`ps axfww|grep soffice.bin|grep 8100|awk -F " " 'NR==1 {print $1}'`
            echo "Alfresco Open Office service already started: $CURRENT_PROCID"
        else
            # Only start if Alfresco is already running
            SHUTDOWN_PORT=`sockstat | grep 8005 | wc -l`

            if [ "$SHUTDOWN_PORT" -ne "0" ]; then
              su -m ${USER} -c '/usr/local/lib/libreoffice/program/soffice.bin -env:UserInstallation=file:///opt/alfresco/alf_data/oouser --accept="socket,host=127.0.0.1,port=8100;urp;StarOffice.ServiceManager" --headless --nocrashreport --nofirststartwizard --nologo --norestore & >/dev/null'
              echo "Alfresco Open Office starting"
            fi
        fi
    }
    stop() {
        OFFICE_PORT=`ps axww|grep soffice.bin|grep 8100|wc -l`
        if [ "$OFFICE_PORT" -ne "0" ]; then
            echo "Alfresco Open Office started, killing $CURRENT_PROCID"
	        CURRENT_PROCID=`ps axfww|grep soffice.bin|grep 8100|awk -F " " 'NR==1 {print $1}'`
	        kill $CURRENT_PROCID
        else
            echo "Not started."
        fi
    }
    status() {
        # Start Tomcat in normal mode
        OFFICE_PORT=`ps axww|grep soffice.bin|grep 8100|wc -l`
        if [ "$OFFICE_PORT" -ne 0 ]; then
            echo "Alfresco LibreOffice service started"
        else
            echo "Alfresco LibreOffice service NOT started"
        fi
    }

    case "$1" in
      start)
            start
            ;;
      stop)
            stop
            ;;
      restart)
            stop
	    sleep 2
            start
            ;;
      status)
            status
            ;;
      *)
            echo "Usage: $0 {start|stop|restart|status}"
            exit 1
    esac

    exit $RETVAL 
