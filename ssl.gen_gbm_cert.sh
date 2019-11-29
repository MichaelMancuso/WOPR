#!/bin/bash

openssl genrsa -out gbm_key.pem 2048
openssl req -new -key gbm_key.pem -out gbm_csr.pem -days
openssl req -x509 -days 1825 -key gbm_key.pem -in gbm_csr.pem -out gbm_certificate.pem

cat gbm_key.pem gbm_certificate.pem > gbm_full_certificate.pem

openssl pkcs12 -export -out gbm_full_certificate.pfx -inkey gbm_key.pem -in gbm_certificate.pem
