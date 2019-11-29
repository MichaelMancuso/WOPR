#!/bin/bash

cd $HOME
ME=`whoami`
sudo chown -R $ME.$ME gnuradio

# To just update 1 component, use pybombs update <module>     e.g.: pybombs update gnuradio
pybombs update

