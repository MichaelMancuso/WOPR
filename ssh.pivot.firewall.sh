#!/bin/bash
echo "Local listener will be https://localhost:8443/"
echo ""
ssh.pivot.sh --localport=8443 --remoteip=172.22.15.1 --remoteport=8443 mpiscopo@wopr.ais.local
