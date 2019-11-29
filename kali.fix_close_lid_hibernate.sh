#!/bin/bash

sed -i "s|#HandleLidSwitch=.*|HandleLidSwitch=ignore|" /etc/systemd/logind.conf
