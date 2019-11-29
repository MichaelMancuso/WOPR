#!/bin/sh

ShowUsage() {
	echo ""
	echo "Usage: $0 <Files>"
	echo "$0 can also be used with nautilus-actions (apt-get -y install wipe nautilus-actions) to provide secure delete via the Nautilus shell."
	echo ""
}

# Check if in XSession or ssh/cmd line only
if [ ${#DISPLAY} -gt 0 ]; then
	INXSESSION=1
else
	INXSESSION=0
fi

if [ $# -eq 0 -o "$1" = "--help" ]; then
	if [ $INXSESSION -eq 0 ]; then
		ShowUsage
	else
		zenity --info --title="Usage" --text="Usage: $0 [Files].  $0 can also be used with nautilus-actions (apt-get -y install wipe nautilus-actions) to provide secure delete via the Nautilus shell."
	fi

	exit 1
fi

if [ "$@" = "$1" ]; then
	if [ $INXSESSION -eq 1 ]; then
		zenity --question --title="Secure Delete [Wipe]" --text="Are you sure you want to permanently delete $@?"
	else
		while true
		do
			echo -n "Are you sure you want to permanently delete $@? [y/n]"
			read -e USER_CONFIRM
			case $USER_CONFIRM
			y|Y|YES|yes|Yes)
				break
			;;
			n|N|no|NO|No)
				echo ""
				echo "Files not deleted."
				exit 1
			;;
			*)
				echo "Please select Y/y or N/n!"
			;;
			esac
		done
	fi
else
	if [ $INXSESSION -eq 1 ]; then
		zenity --question --title="Secure Delete [Wipe]" --text="Are your sure you want to permanently delete the selected files?"
	else
		while true
		do
			echo -n "Are you sure you want to permanently delete the specified files ($@)? [y/n]"
			read -e USER_CONFIRM
			case $USER_CONFIRM
			y|Y|YES|yes|Yes)
				break
			;;
			n|N|no|NO|No)
				echo ""
				echo "Files not deleted."
				exit 1
			;;
			*)
				echo "Please select Y/y or N/n!"
			;;
			esac
		done
	fi
fi

if [ "$?" = 1 ] ; then
	exit $?
else
	wipe -rcfs -qQ 2 "$@"
fi

