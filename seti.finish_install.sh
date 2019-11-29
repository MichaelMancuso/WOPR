#!/bin/bash

echo "[`date`] Configuring application..."

echo "<app_info>" > ~/app_info.xml
echo "	<app>" >> ~/app_info.xml
echo "		<name>setiathome_v8</name>" >> ~/app_info.xml
echo "		<user_friendly_name>SETI@home v8</user_friendly_name>" >> ~/app_info.xml
echo "	</app>" >> ~/app_info.xml
echo "	<file_info>" >> ~/app_info.xml
echo "	<name>setiathome-8.0.armv7l-unknown-linux-gnueabihf</name>" >> ~/app_info.xml
echo "	<executable/>" >> ~/app_info.xml
echo "	</file_info>" >> ~/app_info.xml
echo "	<app_version>" >> ~/app_info.xml
echo "		<app_name>setiathome_v8</app_name>" >> ~/app_info.xml
echo "		<version_num>800</version_num>" >> ~/app_info.xml
echo "		<file_ref>" >> ~/app_info.xml
echo "		<file_name>setiathome-8.0.armv7l-unknown-linux-gnueabihf</file_name>" >> ~/app_info.xml
echo "		<main_program/>" >> ~/app_info.xml
echo "		</file_ref>" >> ~/app_info.xml
echo "	</app_version>" >> ~/app_info.xml
echo "</app_info>" >> ~/app_info.xml

cp ~/setiathome-8.0.armv7l-unknown-linux-gnueabihf /var/lib/boinc-client/projects/setiathome.berkeley.edu/

if [ ! -e /var/lib/boinc-client/projects/setiathome.berkeley.edu/app_info.xml.original ]; then
	cp /var/lib/boinc-client/projects/setiathome.berkeley.edu/app_info.xml /var/lib/boinc-client/projects/setiathome.berkeley.edu/app_info.xml.original
fi

cp ~/app_info.xml /var/lib/boinc-client/projects/setiathome.berkeley.edu/
cp ~/app_info.xml /var/lib/boinc-client/projects/setiathome.berkeley.edu/app_info.new
chown boinc.boinc /var/lib/boinc-client/projects/setiathome.berkeley.edu/*

echo "[`date`] Starting service..."
/etc/init.d/boinc-client restart
systemctl daemon-reload

echo "[`date`] Done."
