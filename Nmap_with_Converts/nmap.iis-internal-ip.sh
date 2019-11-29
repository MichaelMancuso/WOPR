#!/bin/bash

#This program takes an input file that should consist of IIS 6.0 IP addresses and checks for internal IP address disclosure

if [ -z "$1" ]; then
        echo "This script expects a filename for an argument."
        echo "The file should contain a list of IIS 6.0 IP addresses."
        echo "Usage: $0 <input file>"
        exit
fi

echo
echo "Checking servers for IIS 6.0 internal IP address disclosure vulnerability..."
echo

for i in `cat $1`;do
        IP=$(printf  "HEAD /images HTTP/1.0\r\n\r\n" | nc -w 5 $i 80 | grep "Location" | cut -d "/" -f3)
        if [ $i != "$IP" ] && [ "$IP" != "" ]; then
                echo "$i -> $IP"
        fi
done
