#!/bin/bash

# Reference:
# https://github.com/gnuradio/pybombs/blob/master/README.md

# prerequisites (on a base Ubunty 16.04 these may be missing)
HASPYBOMBS=`which pybombs | wc -l`

if [ $HASPYBOMBS -eq 0 ]; then
	sudo apt install -y python-pip python-dev git python-distutils-extra python-ruamel.ordereddict

	# use this if you already have pybombs installed:
	# sudo pip install --upgrade git+https://github.com/gnuradio/pybombs.git

	sudo pip2 install git+https://github.com/gnuradio/pybombs.git

	sudo pip2 install mako python-apt

	pybombs recipes add gr-recipes git+https://github.com/gnuradio/gr-recipes.git
	pybombs recipes add gr-etcetera git+https://github.com/gnuradio/gr-etcetera.git

fi

# gedit ./gnuradio/src/apache-thrift/lib/cpp/src/thrift/transport/TSSLSocket.cpp 2>/dev/null &
echo "If you're on Kali linux and get an apache thrift build error, break the install then edit ./gnuradio/src/apache-thrift/lib/cpp/src/thrift/transport/TSSLSocket.cpp"
echo "Search for SSLv3 and change the call to SSLv3_method() to SSLv23_method()."
echo "If the build doesn't pick back up with apache-thrift, after it's done go into <prefix>/src/apache-thrift and run \"make && make install\""

# This starts the install:  (remember ~ doesn't work in bash scripts so using $HOME instead)
pybombs prefix init $HOME/gnuradio -a myprefix -R gnuradio-default

cat $HOME/.profile | grep -q "setup_env\.sh"

if [ $? -gt 0 ]; then
	# Add it 
	echo "source $HOME/gnuradio/setup_env.sh" >> $HOME/.profile
	echo "export Gnuradio_DIR=\"/$HOME/gnuradio\"" >> $HOME/.profile
fi

echo "Use these commands to run gnuradio:"
echo "source ~/gnuradio/setup_env.sh  (If it wasn't added to .profile)"
echo "gnuradio-companion"

