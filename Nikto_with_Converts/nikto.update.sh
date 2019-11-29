#!/bin/bash
cd /tmp
git clone https://github.com/sullo/nikto.git nikto-2.1.6

cd /opt/nikto
# Backup conf files first...
cp nikto-2.1.6/nikto.conf* .
# Now copy
rm -rf nikto-2.1.6
mv /tmp/nikto-2.1.6 .
cd nikto-2.1.6
# Move some of the git documentation and files around
mkdir docs-other
mv devdocs docs-other
mv documentation docs-other
mv program/* .
rm -rf program
# update the config with our file
cd /opt/nikto
cp nikto.conf* nikto-2.1.6/
# remove tmp version
rm -rf /tmp/nikto-2.1.6

