#!/usr/bin/python3

import requests
import argparse
import time
import re
import sys
import html

try:
    import socks
except:
    print('ERROR: Unable to find socks support.  run "sudo pip3 install requests[socks]"')
    exit(1)
try:
    import browsercookie
except:
    print('ERROR: Unable to find browsercookie library.  run "sudo pip3 install browsercookie"')
    exit(1)
    
FIREFOXUSERAGENTSTRING="Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:23.0) Gecko/20131011 Firefox/23.0"
FIREFOXUBUNTUSTRING="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:57.0) Gecko/20100101 Firefox/57.0"
IPADUSERAGENTSTRING="Mozilla/5.0 (iPad; U; CPU iPad OS 5_0_1 like Mac OS X; en-us) AppleWebKit/535.1+ (KHTML like Gecko) Version/7.2.0.0 Safari/6533.18.5"
#USERAGENTSTRING="$IPADUSERAGENTSTRING"
USERAGENTSTRING=FIREFOXUBUNTUSTRING
SEARCHURL="https://www.linkedin.com/search/results/index/?origin=GLOBAL_SEARCH_HEADER"
session = requests.Session()
session.headers.update({'User-Agent': USERAGENTSTRING})
session.headers.update({'Accept-Language': 'en-US,en;q=0.5'})
session.headers.update({'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'})

proxyDict = None
verify = True
cookies = browsercookie.firefox()

def makeGetRequest(url, waitTimeout=6):
    global proxyDict
    global verify
    global cookies
    
    try:
        # Not using a timeout can cause the request to hang indefinitely
        response = session.get(url, timeout=waitTimeout, proxies=proxyDict, cookies=cookies, verify=verify)
        # cookies = dict(response.cookies)
    except:
        return -1, "Exception making request."
        
    if response.status_code != 200:
        return response.status_code, response.text
        
    htmlResponse=response.text
    return response.status_code, htmlResponse

def getFieldValue(p, curLine):
    matchobj = p.search(curLine)
    
    if not matchobj:
        return ""
        
    try:
        retVal = matchobj.group(1)
    except:
        retVal = ""
        
    return retVal

if __name__ == '__main__':
    argparser = argparse.ArgumentParser(description='Command-line tool to search for URLs discovered by google')
    argparser.add_argument('--company', help='Company to search for', default='', required=True)
    argparser.add_argument('--startpage', help='Staring point for restarted searches', default=0, required=False)
    argparser.add_argument('--httpproxy', help='http proxy ip:port', default='', required=False)
    argparser.add_argument('--socksproxy', help='socks proxy ip:port', default='', required=False)
    argparser.add_argument('--sleeptime', help='Seconds to wait between page requests to prevent getting blocked', default=15, required=False)
    args = argparser.parse_args()

    sleeptime = args.sleeptime
    searchcompany=args.company
    
    verify = True
    
    if len(args.httpproxy) > 0:
        #http_proxy  = "http://127.0.0.1:8080"
        #https_proxy = "https://127.0.0.1:8080"
        http_proxy  = "http://" + args.httpproxy
        https_proxy = "https://" + args.httpproxy

        proxyDict = { 
                      "http"  : http_proxy, 
                      "https" : https_proxy, 
                    }
    elif len(args.socksproxy) > 0:
        http_proxy  = "socks5://" + args.socksproxy
        https_proxy = "socks5://" + args.socksproxy

        proxyDict = { 
                      "http"  : http_proxy, 
                      "https" : https_proxy, 
                    }
        
    searchcompany=searchcompany.replace('"', '')
    
    SEARCHURL = SEARCHURL + '&keywords="' + searchcompany + '"&page='

    p_numresults = re.compile('totalResultCount&quot;:([0-9]{1,})')
    
    responsecode, htmlresult = makeGetRequest(SEARCHURL + "1")
    
    if responsecode == 503:
        print('Uh-oh: You got blacklisted.  Wait a while then try again.', file=sys.stderr)
        exit(1)
    elif responsecode != 200:
        print('ERROR: Error code ' + str(responsecode) + ' occurred.', file=sys.stderr)
        exit(2)
        
    strnumresults = getFieldValue(p_numresults, htmlresult)
    
    if len(strnumresults) == 0:
        print('Error finding number of results returned.', file=sys.stderr)
        exit(3)
    else:
        print('Found ' + strnumresults + ' matches.', file=sys.stderr)
        if int(strnumresults) == 0:
            exit(0)
    
    p_link = re.compile('({&quot;firstName.*?})')
    p_firstname=re.compile('firstName":"(.*?)",')
    p_lastname=re.compile('lastName":"(.*?)",')
    p_title=re.compile('occupation":"(.*?)",')
    
    numresults = int(strnumresults)
    if numresults > 100:
        print('Standard accounts only allow up to 100 results.  Adjusting to 100...', file=sys.stderr)
        numresults = 100
        
    numshown = 0
    curpage = 1
    links = [1]
    addedItems = True
    
    foundnames={}
    
    print('First Name\tLast Name\tTitle')
    
    while numshown < numresults and len(links) > 0 and addedItems:
        responsecode, htmlresult = makeGetRequest(SEARCHURL + str(curpage))
        
        if responsecode != 200:
            print('ERROR: Error code ' + str(responsecode) + ' occurred.', file=sys.stderr)
            exit(2)
            
        links = p_link.findall(htmlresult)
        
        print('Processing item ' + str(numshown+1) + ' of ' + str(numresults) + '...', file=sys.stderr)
        
        addedItems = False
        
        for curlink in links:
            numshown += 1
            try:
                htmlstr = html.unescape(curlink)
                firstName = getFieldValue(p_firstname, htmlstr)
                
                if firstName.endswith('.') and ' ' in firstName:
                    firstName = firstName.split(' ')[0]
                    
                lastName = getFieldValue(p_lastname, htmlstr)
                if ',' in lastName:
                    lastName = lastName.split(',')[0]
                    
                    
                title = getFieldValue(p_title, htmlstr)
                title = title.replace('\n', ' ')
                title = title.replace('\\n', ' ')
                
                if len(firstName) > 0 and len(lastName) > 0:
                    fullname=firstName + ' ' + lastName
                    if not fullname in foundnames:
                        print(firstName + '\t' + lastName + '\t' + title)
                        foundnames[fullname] = fullname
                        addedItems = True
            except:
                pass
        
        curpage += 1
        time.sleep(5)
        
    print('Done.', file=sys.stderr)
    
