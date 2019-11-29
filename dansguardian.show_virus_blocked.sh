#!/bin/bash

cat /var/log/dansguardian/access.log* | grep "Virus or bad content detected"
