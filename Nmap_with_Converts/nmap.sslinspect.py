#!/usr/bin/python3

import subprocess
import re
import argparse
import os
from time import sleep
import sys
from datetime import datetime
from dateutil import parser

def nmapGetCert(ipaddr, port=443):
    result = subprocess.run(['nmap','-Pn', '-n', '-p', str(port), '--script=ssl-cert', ipaddr], 
                            stdout=subprocess.PIPE,stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
    resultOutput = result.stdout.decode('ASCII')
    
    commonName=''
    issuer = ''
    validityDate=''
    
    m = re.search('commonName=(.*)', resultOutput)
    if m is not None:
        commonName=m.group(0).replace('commonName=', '')
        
    m = re.search('Issuer: (.*)', resultOutput)
    if m is not None:
        issuer=m.group(0).replace('Issuer: ', '')
        
    
    m = re.search('Not valid after: (.*)', resultOutput)
    if m is not None:
        validityDate=m.group(0).replace('Not valid after: ', '').strip().replace('T', ' ')
        
        
    return commonName, issuer, validityDate
                            
def nmapGetCiphers(ipaddr, port=443):
    result = subprocess.run(['nmap','-Pn', '-n', '-p', str(port), '--script=ssl-enum-ciphers', ipaddr], 
                            stdout=subprocess.PIPE,stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL)
    resultOutput = result.stdout.decode('ASCII')
    
    retVal = ''
    lines=resultOutput.split('\n')
    
    for curLine in lines:
        if curLine.startswith('|') and not 'ssl-enum-ciphers' in curLine:
            curLine=curLine.replace('|', '').strip()
            if curLine.startswith('_'):
                curLine = curLine.strip('_').strip()
                
            retVal += curLine + ','
            
    retVal = retVal.strip(',')
    
    return retVal

if __name__ == '__main__':
    argparser = argparse.ArgumentParser(description='Command-line tool to dump ssl certificate info')
    group = argparser.add_mutually_exclusive_group(required=True)
    group.add_argument('--inputfile', help='File containing hosts (can be in the format IP[:port] or hostname[:port])', default='', required=False)
    group.add_argument('--host', help='Host to scan (can be in the format IP[:port] or hostname[:port])', default='', required=False)
    argparser.add_argument('--delay', help='Wait between each host check in seconds (port shunning evasion)', default=0, required=False)
    args = argparser.parse_args()
    sleepDelay=int(args.delay)
    
    if len(args.inputfile) == 0 and len(args.host) == 0:
        print('ERROR: Please provide either an input file or a host.')
        print('Usage: --inputfile=<file> or --host=<host>[:port]')
        exit(2)
        
    targets={}
    
    if len(args.inputfile) > 0 and not os.path.exists(args.inputfile):
        print('ERROR: Unable to find input file ' + args.inputfile)
        exit(1)

    if len(args.inputfile) > 0:
        with open(args.inputfile, 'r') as f:        
            for line in f.readlines():
                if len(line) > 0 and not line.startswith('#'):
                    attributes=line.split(':')
                    address=attributes[0].replace('\n', '').strip()
                    if len(address) > 0:
                        if len(attributes) > 1:
                            targets[address] = int(attributes[1].replace('\n', ''))
                        else:
                            targets[address] = 443
    else:
        attributes=args.host.split(':')
        address=attributes[0].strip()
        if len(address) > 0:
            if len(attributes) > 1:
                targets[address] = int(attributes[1].replace('\n', ''))
            else:
                targets[address] = 443
        else:
            print('ERROR: Unable to parse host address from ' + args.host)
            exit(3)
        
    print('Common Name\tIP Address\tPort\tIssuer\tExpiration Date\tSupported Ciphers')

    for curKey in targets.keys():
        commonName, issuer, validityDate = nmapGetCert(curKey, targets[curKey])
        ciphers=nmapGetCiphers(curKey, targets[curKey])

        print(commonName+'\t'+ curKey + '\t' + str(targets[curKey]) + '\t' + issuer + '\t' + validityDate + '\t' + ciphers)
    
        if sleepDelay > 0:
            print('Sleeping ' + str(sleepDelay) + 's between hosts...', file=sys.stderr)    
            sleep(sleepDelay)
    
    print('Done.', file=sys.stderr)    
