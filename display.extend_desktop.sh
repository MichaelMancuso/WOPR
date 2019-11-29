#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <display 1> <display 2> <display 2's position in relation to display 1>"
	echo "Use xrandr to find display names (must be on the local system)"
	echo "positions would be 'right-of' 'left-of' 'above' 'below'"
	echo "or 'same-as' for duplication."
}

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

DISPLAY1NAME=$1
DISPLAY2NAME=$2
POSITION=$3

PARAMS=`echo "--output $DISPLAY2NAME --$POSITION $DISPLAY1NAME"`
xrandr $PARAMS
