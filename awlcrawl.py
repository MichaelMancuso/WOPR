#!/usr/bin/python3

# imports
from bs4 import BeautifulSoup
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
from urllib.parse import urlparse
import pathlib
import argparse

USERAGENTSTRING="Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:57.0) Gecko/20100101 Firefox/57.0"
headers = {}
headers['User-Agent'] = USERAGENTSTRING
headers['Accept-Language'] = 'en-US,en;q=0.5'
headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
waitTimeout=6
verify = False

# These are set in main
in_scope_crawl_domains = []
interestingLinks = []

mediaExtensions = ['ico', 'jpg', 'png', 'svg', 'avi', 'mp3', 'mpeg', 'wmv', 'mp4', 'zip', 'blend', 'tar', 'gz', 'rar', 'ppt', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'pdf']

def isMediaFile(path):
    try:
        extension = pathlib.Path(path).suffix
    except:
        extension = ''
        
    extension = extension.replace('.', '')
    extension = extension.lower()
    
    if extension in mediaExtensions:
        return True
    else:
        return False
    
def getLinks(url, discoveredURLList, interestingURLList,  debug=False):
    global headers
    # Notes:
    # This is cumulative and recursive, so each call passes the list it has in and we add to it as we recurse in.
    try:
        # Not using a timeout can cause the request to hang indefinitely
        r  = requests.get(url, timeout=waitTimeout,  headers=headers, verify=verify)
    except requests.exceptions.SSLError as e:
        print('ERROR on URL ' + url + ': ' + str(e))
        return discoveredURLList, interestingURLList
    except requests.ConnectionError as e:
        print('ERROR on URL ' + url + ': ' + str(e))
        return discoveredURLList, interestingURLList
    except:
        print('ERROR: generic exception on URL' + url)
        return discoveredURLList, interestingURLList

    if r.status_code != 200:
        if debug:
            print('ERROR: Page ' + url + ' returned error code ' + str(r.status_code))
        return discoveredURLList, interestingURLList
        
    print('Scanning ' + url)
    
    data = r.text

    # This didn't help.  PDFs really bog the processor down.
    # isHTML = bool(BeautifulSoup(data, "html.parser").find())
    #if isHTML == False:
    #    return discoveredURLList, interestingURLList
        
    soup = BeautifulSoup(data, "lxml")

    linklist = []
    
    # Extract all links from this page
    
    for link in soup.find_all('link'):
        curLink = link.get('href')
        if curLink is not None:
            if curLink.startswith('//'):
                # Found this incorrect href issue on one site.
                curLink = 'http:' + curLink
                
            if (curLink.upper().startswith('HTTP') == False) and (curLink.startswith('#') == False):
                    curLink = web_site + curLink
                    curLink = curLink.replace('//', '/')
                    curLink = curLink.replace(':/', '://')
                  
            if curLink.lower().startswith('http'):
                linklist.append(curLink)
    
    for link in soup.find_all('a'):
        curLink = link.get('href')
        if curLink is not None:
            if not curLink.upper().startswith('HTTP') and (not curLink.startswith('#')):
                    if curLink.endswith('/'):
                        curLink = web_site + curLink
                    else:
                        curLink = web_site + '/' + curLink
                        
                    curLink = curLink.replace('//', '/')
                    curLink = curLink.replace(':/', '://')
                    
            if curLink.lower().startswith('http'):
                linklist.append(curLink)
    
    # Check if they're in scope for crawling and if so recursively crawl
    inscopeLinks = []
    
    for curLink in linklist:
        inScope = False
        interesting = False
        
        parsedLink=urlparse(curLink)
        parsedDomain = parsedLink.hostname
        
        for curDomain in in_scope_crawl_domains:
            if parsedDomain.lower().endswith(curDomain):
                inScope = True
                break
                
        for curDomain in interestingLinks:
            if parsedDomain.lower().endswith(curDomain):
                interesting = True
                break
                
        if inScope and (curLink not in discoveredURLList):  # Could have the same link in multiple pages, e.g. home
            discoveredURLList.append(curLink)
            inscopeLinks.append(curLink)
            if debug:
                print('In-scope link: ' + curLink)
    
        if interesting and (curLink not in interestingURLList):
            interestingURLList.append(curLink)
            if debug:
                print('Interesting link: ' + curLink)
            
    for curLink in inscopeLinks:
        parsedLink=urlparse(curLink)
        
        if isMediaFile(parsedLink.path) == False:
            if debug:
                print('Recursively crawling ' + curLink)
            discoveredURLList, interestingURLList = getLinks(curLink, discoveredURLList, interestingURLList,  debug)

    return discoveredURLList, interestingURLList
            
if __name__ == "__main__":
    # For now just looking for AWS
    interestingLinks = ['.amazonaws.com']  # See https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html
    
    argparser = argparse.ArgumentParser(description='Amazon Web Services Link Crawler (AWLCrawl)')
    argparser.add_argument('--website', help="Provide the web site to crawl.  Ex: https://www.mysite.com", default='', required=True)
    argparser.add_argument('--verbose', help="Print status info along the way", action='store_true', default=False, required=False)

    args = argparser.parse_args()

    web_site = args.website
    debug = args.verbose

    if web_site.lower().startswith('http') == False:
        print('ERROR: ' + web_site + ' does not look like a valid URL')
        exit(1)
        
    parsedLink=urlparse(web_site)
    hostname = parsedLink.hostname

    domain = hostname.partition('.')[2]
    # domain = 'ecommerce.shopify.com'
    # domain = 'www.blenderguru.com'
    in_scope_crawl_domains = [domain]

    foundCrawlLinks = []
    foundInterestingLinks = []
    
    print('Processing ' + web_site + ' ...')

    foundCrawlLinks, foundInterestingLinks = getLinks(web_site, foundCrawlLinks, foundInterestingLinks, debug)
    
    print('Links crawled: ' + str(len(foundCrawlLinks)+1))
    
    if len(foundInterestingLinks) > 0:
        print(str(len(foundInterestingLinks)) + 'Interesting links found:')
        
        for curLink in foundInterestingLinks:
            print(curLink)
    else:
        print('No interesting links found.')
        
    print('Done.')
    
