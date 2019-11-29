#!/bin/bash

wget -O- http://www.mybrowserinfo.com 2>/dev/null | grep -Eo "Your IP Address is [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed "s|Your IP Address is ||"
