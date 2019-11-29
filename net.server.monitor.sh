#!/bin/bash
watch -n 5 "netstat -an | grep ':5222' | grep -v tcp6"
