#!/bin/sh
# -------
# Script to generate self signed ssl certs
# 
# Copyright 2015, Kristoffer Andergrim
# Based on alfresco-ubuntu-install by Peter Löfgren, Loftux AB
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------

mkdir -p /usr/local/etc/nginx/ssl
cd /usr/local/etc/nginx/ssl
openssl genrsa -des3 -out alfserver.key 1024
openssl req -new -key alfserver.key -out alfserver.csr
cp alfserver.key alfserver.key.org
openssl rsa -in alfserver.key.org -out alfserver.key
openssl x509 -req -days 1825 -in alfserver.csr -signkey alfserver.key -out alfserver.crt