#!/usr/bin/env bash

# Many thanks https://gist.github.com/mtigas/952344

# Generate CA key
openssl genrsa -aes256 -passout pass:xxxx -out ca.pass.key 4096
openssl rsa -passin pass:xxxx -in ca.pass.key -out ca.key
rm ca.pass.key

# Generate CA root cert
openssl req -new -x509 -days 3650 -key ca.key -out ca.pem

# Generate client key
openssl genrsa -aes256 -passout pass:xxxx -out client.pass.key 4096
openssl rsa -passin pass:xxxx -in client.pass.key -out client.key
rm client.pass.key

# Generate CSR
openssl req -new -key client.key -out client.csr

# Issue certificate signed by CA
openssl x509 -req -days 3650 -in client.csr -CA ca.pem -CAkey ca.key -set_serial 01 -out client.pem

# Bundle key into pfx to be installed in browser
openssl pkcs12 -export -out client.p12 -inkey client.key -in client.pem -certfile ca.pem

# Remove files which are not needed
rm ca.key client.csr client.key client.pem
