#!/bin/bash

ShowUsage() {
	echo "Usage: $0 <sftp username>"
}

if [ $# -eq 0 ]; then
	ShowUsage
	exit 1
fi

# Make a group called sftp_users
# groupadd sftp_users
# Add this to the end of sshd_config
# This got added to the bottom of sshd_config:
# Match Group sftp_users
# X11Forwarding no
# AllowTcpForwarding no
# ChrootDirectory %h
# ForceCommand internal-sftp

USERNAME=$1
useradd -M -G sftp_users $USERNAME
passwd $USERNAME
mkdir /home/$USERNAME
chmod 755 /home/$USERNAME
chown root /home/$USERNAME
chgrp sftp_users /home/$USERNAME

mkdir /home/$USERNAME/upload
chown $USERNAME /home/$USERNAME/upload
chmod 775 /home/$USERNAME/upload

sed -i "s|\/home\/$USERNAME.*|\/home\/$USERNAME:/usr/bin/nologin|" /etc/passwd
