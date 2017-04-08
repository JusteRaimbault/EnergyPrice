
import os,sys,traceback,requests,time,re
from lxml import html,etree
import utils

start = time.time()

datadir = 'data'
locdir = 'loc'

if not os.path.exists(locdir):
    os.makedirs(locdir)

if not os.path.isfile(locdir+'/adresses.csv'):
    utils.append_csv([['id','address','locality','region','code']],locdir+'/adresses.csv',';')

# tor port as argument (to be run in // of collection)
port = sys.argv[1]
proxies = {'http':'socks5://localhost:'+port}

# read ids to collect from existing data
ids = set()
for datafile in os.listdir(datadir):
    if re.search('data',datafile) :
        print(datafile)
        for line in utils.read_csv(datadir+'/'+datafile,';'):
            ids.add(line[0])


# read already collected adresses
existing = set()
if os.path.isfile(locdir+'/adresses.csv'):
    for line in utils.read_csv(locdir+'/adresses.csv',';'):
        if len(line)>1 :
            existing.add(line[0])

# get uncollected
uncollected = ids.difference(existing)

print('Effectively collecting '+str(len(uncollected))+' adresses')

errorfile = open(locdir+'/errors.csv','a')



#data = []

for station_id in uncollected :
    print('id : '+str(station_id))
    try :
        result = requests.get(url+str(station_id),proxies=proxies)
        tree = html.fromstring(result.content)
#        #
        if len(tree.find_class("station-address")) > 0 :
            address = ''
            try :
                address = tree.xpath("//div[@itemprop='address']")[0]
            except :
                print('station '+str(station_id)+' has no address')
            street_address = ''
            try :
                street_address = address.xpath("//div[@itemprop='streetAddress']/text()")[0]
            except :
                print('station '+str(station_id)+' has no street address')
            locality = ''
            try :
                locality = address.xpath("//span[@itemprop='addressLocality']/text()")[0]
            except :
                print('station '+str(station_id)+' has no locality')
            region = ''
            try :
                region = address.xpath("//span[@itemprop='addressRegion']/text()")[0]
            except :
                print('station '+str(station_id)+' has no region')
            code = ''
            try :
                code = address.xpath("//span[@itemprop='postalCode']/text()")[0]
            except :
                print('station '+str(station_id)+' has no code')
#            # append to data
#            #data.append([station_id,street_address,locality,region,code])
#            # shitty vps -> memory problem -> append directly to file
            utils.append_csv([[station_id,street_address,locality,region,code]],locdir+'/adresses.csv',';')
        else :
            errorfile.write(str(station_id)+'\n')
    except Exception :
        #exc_type, exc_value, exc_traceback = sys.exc_info()
        #traceback.print_exception(exc_type, exc_value, exc_traceback,2,'error_log')
        print(traceback.format_exc())
        print("error getting station "+str(station_id))
        errorfile.write(str(station_id)+'\n')
#
## append data to adress file

## create file with header if not exists
##if not os.path.exists(locdir):
##    os.makedirs(locdir)

##if not os.path.isfile(locdir+'/adresses.csv'):
##    utils.append_csv([['id','address','locality','region','code']],locdir+'/adresses.csv',';')

##utils.append_csv(data,locdir+'/adresses.csv',';')

print('Ellapsed Time : '+str(time.time() - start))
