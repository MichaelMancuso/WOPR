#!/bin/bash

lsusb -v | grep -i -e "^Bus" -e "maxpower"

