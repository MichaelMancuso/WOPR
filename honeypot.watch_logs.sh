#!/bin/bash

tail -f /opt/honeypots/cowrie-ssh/log/cowrie.log /var/log/apache2/access.log | grep -v awstats
