#!/bin/bash
echo "John 1.8.0 introduced some new options.  You can/should still edit the make file and enable 'OMPFLAGS = -fopenmp'"
echo "However a --fork option is now available for multi-threaded use on a single box.  This can be used instead of mpiexec -np <n> on a local machine and may be faster as it won't have the MPI overhead"
echo "If a 1.8.x jumbo is not available on the site, can get it from github with:"
echo " wget -o john-1.8.x-jumbo-bleeding.tar.gz https://github.com/magnumripper/JohnTheRipper/tarball/bleeding-jumbo"

