
import os,sys,traceback,requests,time
from lxml import html,etree
import utils

start = time.time()

datadir = 'data'
locdir = 'loc'

# tor port as argument (to be run in // of collection)
port = sys.argv[1]
proxies = {'http':'socks5://localhost:'+port}

# read ids to collect from existing data
ids = set()
for datafile in os.listdir(datadir):
    for line in utils.read_csv(datadir+'/'+datafile,';'):
        ids.add(line[0])


# read already collected adresses
existing = set()
if os.path.isfile(locdir+'/adresses.csv'):
    for line in utils.read_csv(locdir+'/adresses.csv'):
        existing.append(line[0])

# get uncollected
uncollected = ids.difference(existing)

print('Effectively collecting '+str(len(uncollected))+' adresses')

errorfile = open(locdir+'/errors.csv','a')

data = []

for station_id in uncollected :
    print('id : '+str(station_id))
    try :
        result = requests.get('http://www.gasbuddy.com/Station/'+str(station_id),proxies=proxies)
        tree = html.fromstring(result.content)
        #
        if len(tree.find_class("station-address")) > 0 :
            address = tree.xpath("//div[@itemprop='address']")[0]
            street_address = address.xpath("//div[@itemprop='streetAddress']/text()")[0]
            locality = address.xpath("//span[@itemprop='addressLocality']/text()")[0]
            region = address.xpath("//span[@itemprop='addressRegion']/text()")[0]
            code = address.xpath("//span[@itemprop='postalCode']/text()")[0]
            # append to data
            data.append([station_id,street_address,locality,region,code])
        else :
            errorfile.write(str(station_id)+'\n')
    except Exception :
        #exc_type, exc_value, exc_traceback = sys.exc_info()
        #traceback.print_exception(exc_type, exc_value, exc_traceback,2,'error_log')
        print(traceback.format_exc())
        print("error getting station "+str(station_id))
        errorfile.write(str(station_id)+'\n')

# append data to adress file

# create file with header if not exists
if not os.path.exists(locdir):
    os.makedirs(locdir)

if not os.path.isfile(locdir+'/adresses.csv'):
    utils.append_csv([['id','address','locality','region','code']],locdir+'/adresses.csv',';')

utils.append_csv(data,locdir+'/adresses.csv',';')

print('Ellapsed Time for task : '+str(taskid)+' :'+str(time.time() - start))
