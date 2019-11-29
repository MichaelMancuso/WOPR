#!/bin/bash

# According to http://serverfault.com/questions/707377/slow-ssh-login-activation-of-org-freedesktop-login1-timed-out
# This can happen if the dbus is restarted but the systemd-logind service is not.  Just restart systemd-logind to fix it.
#

systemctl restart systemd-logind
