#!/bin/bash

# warning - must be run from kafka directory
set -e

CA_DIR=ca
TS_DIR=truststore

# remove old files
rm -rf $CA_DIR/*
rm -rf $TS_DIR/*

# Create CA Certificate
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -days 36500 -out $CA_DIR/cacert.pem -keyout $CA_DIR/cakey.pem -outform PEM -subj "/C=KR/ST=Chungcheongbuk/L=Cheongju/O=CBNU/CN=localhost"
# Create Truststore for client
keytool -noprompt -keystore $TS_DIR/client.truststore.jks -alias CARoot -import -file $CA_DIR/cacert.pem -storepass 123456
# Create Truststore for server
keytool -noprompt -keystore $TS_DIR/server.truststore.jks -alias CARoot -import -file $CA_DIR/cacert.pem -storepass 123456

# create a database and serial number file
echo 01 > $CA_DIR/serial.txt
touch $CA_DIR/index.txt
echo 'unique_subject = no' > $CA_DIR/index.txt.attr
