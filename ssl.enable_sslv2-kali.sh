cd /tmp
mkdir opensslrebuild
cd opensslrebuild
apt-get -y install devscripts quilt
apt-get source openssl
cd openssl-*
quilt pop -a

sed -i "s|ssltest_no_sslv2.patch$||" debian/patches/series
sed -i "s|no-ssl2||" debian/rules
dch –n 'Allow SSLv2'
dpkg-source --commit
debuild -uc -us
cd ..
dpkg -i *ssl*.deb
