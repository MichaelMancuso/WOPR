#!/bin/bash

ping6 -c4 -I eth0 ff02::1

ip -6 neigh show
