#!/bin/bash

# This is only needed for plane and we're just doing copter
# See this link: http://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html#setting-up-sitl-on-linux

# export PATH=$PATH:/opt/drone/jsbsim/src
export PATH=$PATH:/opt/drone/ardupilot/Tools/autotest
export PATH=/usr/lib/ccache:$PATH

cd /opt/drone/ardupilot/ArduCopter
# Do this on initial setup
# python2 `which sim_vehicle.py` -w

# then kill that and run 
python2 `which sim_vehicle.py` --console --map --aircraft test

# test with these in the window/cmd prompt where you ran the command to start, not the OTHER console
# mode alt_hold
# arm throttle
# 1500 is center stick.  < 1500 is one way, > 1500 is the other.  2000 is max. 1000 is min.
# rc # where # is direction.
# rc 3 1700  (range 1000-2000, 1500 is center stick)
# rc 1 = left/right
# rc 2 = forward / back
# rc 3 = vertical
# there's takeoff/land commands too.

