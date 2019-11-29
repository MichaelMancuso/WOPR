#!/bin/bash

B200UTILEXE=`locate b2xx_fx3_utils | grep "b2xx_fx3_utils$" | head -1`

if [ ${#B200UTILEXE} -gt 0 ]; then
	echo "[`date`] Resetting B200..."
	$B200UTILEXE --reset-device
else
	echo "[`date`] ERROR: Unable to locate b2xx_fx3_utils"
fi



