#!/bin/bash

watch -n 5 'netstat -an | grep -e ":443" -e ":5444" -e ":5222"'

