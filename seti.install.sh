#!/bin/bash

apt-get install boinc-app-seti boinc-manager

echo "When ready, edit /etc/init.d/boinc-client and set ENABLED=1 then start the service."
