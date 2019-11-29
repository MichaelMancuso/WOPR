#!/bin/bash

# This is just a wrapper for calling the dbeaver universal database client.

if [ -e /usr/share/dbeaver/dbeaver ]; then
	/usr/share/dbeaver/dbeaver
else
	echo "ERROR: Can't find dbeaver.  Please install the deb package."
fi

