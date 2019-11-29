#!/bin/bash

# Ref: http://ubuntuforums.org/showthread.php?t=1810262

grep "xset s off" $HOME/.bashrc

if [ $? -gt 0 ]; then
	# Add it
	CONFIGSCRIPT="$HOME/.bashrc"

	echo 'echo "$DISPLAY" | grep -q ":0"' >> $CONFIGSCRIPT
	echo 'if [ $? -eq 0 ]; then' >> $CONFIGSCRIPT
	echo -e "\txset -dpms" >> $CONFIGSCRIPT
	echo -e "\txset s noblank" >> $CONFIGSCRIPT
	echo -e "\txset s off" >> $CONFIGSCRIPT
	echo "fi" >> $CONFIGSCRIPT
fi

if [ ! -e $HOME/.config/autostart ]; then
	mkdir $HOME/.config/autostart
	
	echo '#!/bin/bash' > $CONFIGSCRIPT
	echo "xset -dpms" >> $CONFIGSCRIPT
	echo "xset s noblank" >> $CONFIGSCRIPT
	echo "xset s off" >> $CONFIGSCRIPT
	chmod +x $CONFIGSCRIPT
fi

xset -dpms
xset s noblank
xset s off
