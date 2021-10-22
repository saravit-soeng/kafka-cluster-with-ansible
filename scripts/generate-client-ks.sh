#!/bin/bash

# warning - must be run from kafka directory
set -e
KS_DIR=keystore
CA_DIR=ca

# remove old files
rm -rf $KS_DIR/*

# - name: create keystore
keytool -noprompt -keystore $KS_DIR/client.keystore.jks -alias localhost -validity 36500 -genkey -keyalg RSA -deststoretype pkcs12 -keypass 123456 -storepass 123456 -dname "CN=localhost, OU=Bigdatalabs, O=CBNU, L=Cheongju, S=Chungcheongbuk, C=KR"

# - name: create certificate signing request 
keytool -noprompt -keystore $KS_DIR/client.keystore.jks -alias localhost -certreq -file $KS_DIR/ca-req.csr -storepass 123456

# - name: sign the certificate with CA
openssl ca -batch -config config/openssl-ca-on-client.cnf -policy signing_policy -extensions signing_req -out $KS_DIR/ca-signed.pem -infiles $KS_DIR/ca-req.csr

# - name: import ca into keystore
keytool -noprompt -keystore $KS_DIR/client.keystore.jks -alias CARoot -import -file $CA_DIR/cacert.pem -storepass 123456

# - name: import certificate signed by ca into keystore
keytool -noprompt -keystore $KS_DIR/client.keystore.jks -alias localhost -import -file $KS_DIR/ca-signed.pem -storepass 123456

# remove unused files
rm -f $KS_DIR/ca-signed.pem $KS_DIR/ca-req.csr
