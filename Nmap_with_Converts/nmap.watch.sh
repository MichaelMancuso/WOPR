#!/bin/bash

watch -n 5 "ps aux | grep nmap | grep -v -e grep -e watch"
