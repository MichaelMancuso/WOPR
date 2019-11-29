#!/bin/sh
openssl genrsa -des3 -out private.key 2048
echo "Note: Do not enter an email, challenge password or optional company name for CSR"
echo "Also, the generated server must support server AND client authentication for wireless authentication"
openssl req -new -key private.key -out commercial_server.csr

