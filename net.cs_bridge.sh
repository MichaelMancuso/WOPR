#!/bin/bash

ncat -l 8000 --sh-exec "ncat -l 8080"

