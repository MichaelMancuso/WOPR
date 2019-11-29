#!/bin/bash

# Generate local private key
openssl genrsa -out key.pem 2048
# Create cert request
openssl req -new -key key.pem -out csr_request.pem
# Issue certificate
openssl req -x509 -days 1095 -key key.pem -in csr_request.pem -out gened_certificate.pem

# will need both the private key (key.pem) and the gen'd cert (gened_certificate.pem)
