#!/bin/bash
echo "John Password Cracking Tips"
echo "1. Run john (a multi-core build) with:"
echo "   ./john --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules --fork=<num cores> <password file>"
echo "   This will use the word mangling rules and multi-core acceleration."
echo "2. If that doesn't work try light character sets to 7 characters first."
echo "   ./john -i=Alnum <incremental crack set.  e.g. Alnum.  See john.conf> --fork=<numcores> <password file>"
echo "3. Full on brute force:"
echo "   ./john --incremental --fork=<num cores> <password file>"
echo "4. To use GPU's:  ./john --fork=3 --dev=0,1,2 --format=<hash>-opencl --wordlist=/opt/wordlists/MikesList.wordlist.txt --rules=WordListMike <file>"
echo "   match fork=<num> with the num of GPU devices, so for 1 just use --dev=0, for 2 use --fork=2 --dev=0,1, etc."
echo ""
echo "This has some good examples: http://www.openwall.com/john/doc/EXAMPLES.shtml"
echo ""