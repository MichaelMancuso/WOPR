#!/bin/bash

# http://www.logix.cz/michal/devel/smtp-cli/

apt-get -y install libio-socket-ssl-perl libdigest-hmac-perl libterm-readkey-perl libmime-lite-perl libfile-type-perl libio-socket-inet6-perl

if [ ! -e /usr/bin/smtp-cli ]; then
	echo "Local version not found.  Downloading latest..."
	wget -O smtp-cli http://www.logix.cz/michal/devel/smtp-cli/smtp-cli 2>/dev/null

	sudo cp smtp-cli /usr/bin
	sudo chmod +x /usr/bin/smtp-cli
fi

echo "Install complete."
