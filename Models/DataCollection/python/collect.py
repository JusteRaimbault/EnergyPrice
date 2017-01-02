
# data collection worker script

import requests,sys
from lxml import html,etree
import utils


taskid = int(sys.args[1])

# read station ids from file
ids = utils.read_csv('tmp/ids'+str(taskid),';')

# socks
proxies = {'http':'http://localhost:'+str(9050+taskid)}

# getting html from url
#result = requests.get('www.gasbuddy.com/Station/$i')
#tree = html.fromstring(result.content)
