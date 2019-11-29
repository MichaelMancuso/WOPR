#!/usr/bin/python3

# from xml.dom import minidom
import xml.etree.ElementTree
from bs4 import BeautifulSoup

import argparse
import os

if __name__ == '__main__':
    argparser = argparse.ArgumentParser(description='Command-line tool to format Burp Suite vulnerability results saved as XML')
    argparser.add_argument('--inputfile', help='BurpSuite vulnerabilities saved as XML', default='', required=True)
    args = argparser.parse_args()

    if len(args.inputfile) > 0 and not os.path.exists(args.inputfile):
        print('ERROR: Unable to find input file ' + args.inputfile)
        exit(1)

    try:
        # xmldoc = minidom.parse(args.inputfile)
        e = xml.etree.ElementTree.parse(args.inputfile).getroot()
    except:
        print('ERROR parsing input file.')
        exit(2)
        
    issues = e.findall('issue')
    
    if len(issues) > 0:
        print('Host\tURL\tAuth Status\tNumber\tSeverity\tTitle\tTechnical Details\tRisk\tRemediation\tRequest Type\tPayload\tRequest')
        
        for issue in issues:
            issueDetail = BeautifulSoup(issue.find('issueDetail').text, "lxml").get_text().replace('\n', '  ')
            issueBackground = BeautifulSoup(issue.find('issueBackground').text, "lxml").get_text().replace('\n', '  ')
            remediationBackground = BeautifulSoup(issue.find('remediationBackground').text, "lxml").get_text().replace('\n', '  ')
            request=issue.find('requestresponse').find('request')
            requestBody=request.text.replace('\n', ',')
            
            print(issue.find('host').text + '\t' + issue.find('path').text + '\t' + 'NA' + '\t'  + issue.find('type').text + '\t' + issue.find('severity').text + '\t' + 
                        issueDetail + '\t' + issueBackground  + '\t\t' + remediationBackground + '\t' +  request.attrib['method'] + '\t' + '\t"' + requestBody + '"')
    else:
        print('ERROR: No issues found.')
        
