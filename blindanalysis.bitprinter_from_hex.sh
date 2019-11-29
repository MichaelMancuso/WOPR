#!/usr/bin/python

from __future__ import print_function
# from functools import partial
import sys,getopt,os.path

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def main(argv):
    filename=''

    if len(sys.argv) < 2:
        print('Usage: blindanalysis.bitprinter_from_hex.sh -i <inputfile>')
        print('bitprinter is meant to work with long hex strings in <inputfile> and print out the bit representation.')
        sys.exit(1)

    try:
        opts, args = getopt.getopt(argv,"hi:",["ifile="])
    except getopt.GetoptError:
        print('Usage: blindanalysis.bitprinter_from_hex.sh -i <inputfile>')
        print('bitprinter is meant to work with long hex strings in <inputfile> and print out the bit representation.')
        sys.exit(1)

    for opt, arg in opts:
        if opt == '-h':
            print('Usage: blindanalysis.bitprinter_from_hex.sh -i <inputfile>')
            print('bitprinter is meant to work with long hex strings in <inputfile> and print out the bit representation.')
            sys.exit()
        elif opt in ("-i","--ifile"):
            filename=arg

    if len(filename) == 0:
        print ("Error: please provide an input file.")
        sys.exit(2)

    if not os.path.isfile(filename):
        print ("Error: '", filename, "' does not exist.")
        sys.exit(2)

    eprint('Processing ', filename,"\n")

    with open(filename, 'r') as file:
        hex_lines=file.read().splitlines()
        
        for hexa_input in hex_lines:
            print('Hex input:')
            print(hexa_input)

            print('')
            print('Binary:')
            binary_string = ''.join([bin(int(x,16)+16)[3:] for y,x in enumerate(hexa_input)])
            print(binary_string)
      
    print('')
    eprint("Done.\n")

if __name__ == "__main__":
    main(sys.argv[1:])

