#!/usr/bin/python3

import requests
import argparse
import time
import re
import sys
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
#GOOGLEURL="https://www.google.com/search?num=50&client=firefox-a&rls=org.mozilla%3Aen-US%3Aofficial&noj=1&site=webhp&source=hp&filter=0&q=site:sitetoken"
#GOOGLEURL="https://www.google.com/search?num=50&client=firefox-a&rls=org.mozilla%3Aen-US%3Aofficial&noj=1&site=webhp&source=hp&filter=0&q=site:"
GOOGLEURL="https://www.google.com/search?num=50&source=hp&filter=0"
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
    argparser.add_argument('--site', help='Site or domain to search for.  e.g. mydomain.com or www.mydomain.com', default='', required=True)
    argparser.add_argument('--startpage', help='Staring point for restarted searches', default=0, required=False)
    argparser.add_argument('--httpproxy', help='http proxy ip:port', default='', required=False)
    argparser.add_argument('--socksproxy', help='socks proxy ip:port', default='', required=False)
    argparser.add_argument('--insecure', help='Allow self-signed certs', action='store_false', default=True, required=False)
    argparser.add_argument('--sleeptime', help='Seconds to wait between page requests to prevent getting blocked', default=15, required=False)
    argparser.add_argument('--overrideurl', help='override search url', default='', required=False)
    args = argparser.parse_args()

    sleeptime = args.sleeptime
    searchdomain=args.site
    
    verify = args.insecure
    
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
        
    if len(args.overrideurl) == 0:
        GOOGLEURL = GOOGLEURL + "&q=site%3A" + searchdomain + "&oq=site%3A" + searchdomain
    else:
        GOOGLEURL = args.overrideurl
        
    p_numresults = re.compile('resultStats.>(.*?) results')
    
    responsecode, htmlresult = makeGetRequest(GOOGLEURL)
    
    if responsecode == 503:
        print('Uh-oh: You got blacklisted by Google.  Wait a while then try again.', file=sys.stderr)
        exit(1)
    elif responsecode != 200:
        print('ERROR: Error code ' + str(responsecode) + ' occurred.', file=sys.stderr)
        exit(2)
        
    strnumresults = getFieldValue(p_numresults, htmlresult)
    
    if strnumresults == 0:
        print('Error finding number of results returned.', file=sys.stderr)
        exit(3)
        
    numresults = strnumresults.replace('About ', '').replace(' ', '').replace(',', '')
    p_number = re.compile('([0-9]{1,})')
    
    strnumresults = getFieldValue(p_number, numresults)
    
    numresults = int(strnumresults)
    
    if numresults == 0:
        print('WARNING: No results found.', file=sys.stderr)
        exit(0)
        
    if numresults > 3000:
        print('INFO: More than 3000 results.  Capping at the first 3,000 findings...', file=sys.stderr)
        numresults = 3000
        
    numpages = int(numresults / 50)
    intnumresults = int(numpages * 50)
    
    print( 'Number of search results for ' + searchdomain + ': ' + str(numresults) + ' (' + str(numpages) + ' fifty-link pages)', file=sys.stderr)
    
    
    p_link = re.compile('<a href=\"(.*?)\"')

    startpage = int(args.startpage)
    
    if startpage == 0:
        # First page
        links = p_link.findall(htmlresult)
        
        for curlink in links:
            link = curlink.replace('<a href=', '').replace('"', '')
            
            if link.startswith('http') and not ('myaccount.google.com' in link):
                print(link)
            
        applydelay = True
    else:
        applydelay = False
    
    # Subsequent pages:
    
    if numpages > 1:
        for i in range(startpage-1, numpages+1):
            if applydelay:
                print("Sleeping " + str(sleeptime) + 's for page ' + str(i + 1) + ' of ' + str(numpages) + ' to not be detected as a bot...', file=sys.stderr)
                time.sleep(sleeptime)
            else:
                applydelay = True
                
            curpage = 50 * i
            requesturl = GOOGLEURL + "&start=" + str(curpage)
            responsecode, htmlresult = makeGetRequest(requesturl)
            
            if responsecode == 503:
                print('Uh-oh: You got blacklisted by Google.  Wait a while then try again.', file=sys.stderr)
                exit(1)
            elif responsecode != 200:
                print('ERROR: Error code ' + str(responsecode) + ' occurred.', file=sys.stderr)
                exit(2)
            
            links = p_link.findall(htmlresult)
    
            for curlink in links:
                link = curlink.replace('<a href=', '').replace('"', '')
                
                if link.startswith('http') and not ('myaccount.google.com' in link):
                    print(link)

    print('Done', file=sys.stderr)
