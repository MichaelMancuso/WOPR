#!/usr/bin/python3
import argparse

if __name__ == '__main__':
    # Command-line args for the file
    argparser = argparse.ArgumentParser(description='Command-line tool to extract bits from inspectrum float output')
    argparser.add_argument('--file', help='text file with saved foats', default='', required=True)
    args = argparser.parse_args()

    datafile=open(args.file,'r')
    data=datafile.read()
    
    values=data.split(',')
    
    bits=[]
    for curValue in values:
        curValue = curValue.replace(' ', '').replace('\n', '')
        if len(curValue) > 0:
            try:
                if float(curValue) > 0.0:
                    bits.append(1)
                else:
                    bits.append(0)
            except:
                print('Error converting ' + curValue + ' len=' + str(len(curValue)))
            
    bitstr=str(bits)
    bitstr = bitstr.replace('[','').replace(']','').replace(',','')
    
    print(bitstr)
    
