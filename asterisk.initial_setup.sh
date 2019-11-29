#!/bin/bash

# Just make sure that the addons-ooh323 matches the asterisk version you have installed.
# If it wants to install a different asterisk version, you may have the wrong asterisk<##> specified.  
# Use yum search ooh323 to find the options.
yum install asterisk11-addons-ooh323.x86_64
yum update

# Then reboot
