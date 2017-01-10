
# data collection worker script

import requests,sys,time,traceback
from lxml import html,etree
import utils

start = time.time()

#tmpdir = 'test/tmp/'
tmpdir = 'tmp/'

taskid = int(sys.argv[1])

def get_prices(elem,searchstr,station_id):
    res = []
    fueltype = p[0].text
    # both cash and credit separately
    box = p.find_class(searchstr+"-box")
    if len(box) > 0 :
        currentprice = box[0].find_class("price-display")[0].text
        if currentprice is not None :
            # get time and user
            currenttime = str(box[0].find_class("price-time")[0].text.split(' ')[0])
            currentuser = str(box[0].find_class("memberId")[0].text)
            print(str(station_id)+";"+fueltype+';'+str(currentprice)+';'+currenttime+';'+currentuser)
            res = [str(station_id),fueltype,str(currentprice),currenttime,currentuser,str(int(time.time()))]
    return(res)




# read station ids from file
ids = utils.read_csv(tmpdir+'ids'+str(taskid),';')
errorfile = open(tmpdir+'errors','a')
emptyfile = open(tmpdir+'empty','a')
nostationfile = open(tmpdir+'nostation','a')

# socks
proxies = {'http':'socks5://localhost:'+str(9050+taskid)}

data = []

for station_id in ids :
    print('id : '+str(station_id))
    try :
        # getting html from url
        result = requests.get('http://www.gasbuddy.com/Station/'+str(station_id),proxies=proxies)
        #result = requests.get('http://www.gasbuddy.com/Station/'+str(station_id))
        try :
            tree = html.fromstring(result.content)
        except Exception :
            nostationfile.write(str(station_id)+'\n')
        # elements (by class) : price-display credit-price ; station-address
        # test if address, condition for station to exist
        if len(tree.find_class("station-address")) > 0 :
            for p in tree.get_element_by_id("prices").find_class("white-box") :
                cashprices = get_prices(p,"cash",station_id)
                creditprices = get_prices(p,"credit",station_id)
                if len(cashprices)+len(creditprices) == 0 : emptyfile.write(str(station_id)+'\n')
                if len(cashprices) > 0 : data.append(cashprices)
                if len(creditprices) > 0 : data.append(creditprices)
        else :
            nostationfile.write(str(station_id)+'\n')
    except Exception :
        exc_type, exc_value, exc_traceback = sys.exc_info()
        traceback.print_exception(exc_type, exc_value, exc_traceback,2,error_log)
        #print(str(exc_traceback))
        print("error getting station "+str(station_id))
        errorfile.write(str(station_id)+'\n')


utils.append_csv(data,tmpdir+'data',';')

open(tmpdir+'time'+str(taskid),'a').write(str(time.time() - start))
print('Ellapsed Time for task : '+str(taskid)+' :'+str(time.time() - start))
