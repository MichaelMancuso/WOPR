#!/bin/bash

udevadm control --reload-rules
udevadm trigger
