#!/bin/bash

echo "To encrypt and decrypt with AES, use the appropriate following syntax with OpenSSL:"
echo "(Note you can add -d to decrypt, -a to base64 encode, and -k to include a password on the command-line [otherwise you will be prompted for it])"
echo ""
echo "1.  openssl aes-256-cbc -nosalt -in <input file> -out <output file> [-k <password>]"
echo "2.  echo \"Hello\" | openssl -nosalt aes-256-cbc [-k <password>]"
echo ""
echo "aes-256-cbc can also be replaced by other algorithms such as aes-128-cbc."
echo "Also note that openssl will by default apply a salt [as if -salt were specified].  The generated 8 character salt bytes are prepended to the output string.  If you are attempting to compute an AES encrypted value given a password, the salt needs to be disabled or it will polute the data."

