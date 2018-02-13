
# data collection worker script

import requests,sys,time,traceback
from lxml import html,etree
import utils

start = time.time()

tmpdir = 'test/tmp/'
#tmpdir = 'tmp/'

#taskid = int(sys.argv[1])
taskid = -1

def get_prices(elem,searchstr,station_id):
    res = []
    fueltype = elem.find_class("styles__fuelTypeHeader___2RL00")[0].text
    print(fueltype)
    # both cash and credit separately
    #box = p.find_class(searchstr+"-box")
    box = elem.find_class("styles__priceCardRow___1Rd2v")
    if len(box) > 1 :
        if (len(box[0].find_class("styles__cash___6atBi"))>0) and (searchstr=="cash") :
            currentel = box[0]
        else :
            if searchstr=="cash" :
                return []
            else :
                currentel = box[1]
        currentprice = currentel.find_class("styles__price___1wJ_R")[0].text
        print(currentprice)
        if currentprice is not None :
            # get time and user
            currenttime = str(currentel.find_class("styles__reportedTime___EIf9S")[0].text.split(' ')[0])
            currentuser = str(currentel.find_class("styles__reportedBy___1Q_oZ")[0].text)
            print(str(station_id)+";"+fueltype+';'+str(currentprice)+';'+currenttime+';'+currentuser+';'+searchstr)
            res = [str(station_id),fueltype,str(currentprice),currenttime,currentuser,str(int(time.time())),searchstr]
    return(res)




# read station ids from file
#ids = utils.read_csv(tmpdir+'ids'+str(taskid),';')
ids = ['139091','139342']
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
        if len(tree.find_class("description")) > 0 :
            for p in tree.find_class("styles__pricePanel___3CZK0") :#tree.get_element_by_id("prices").find_class("white-box") :
                cashprices = get_prices(p,"cash",station_id)#+['cash']
                creditprices = get_prices(p,"credit",station_id)#+['credit']
                if len(cashprices)+len(creditprices) == 0 : emptyfile.write(str(station_id)+'\n')
                if len(cashprices) > 0 : data.append(cashprices)
                if len(creditprices) > 0 : data.append(creditprices)
        else :
            print(station_id)
            nostationfile.write(str(station_id)+'\n')
    except Exception :
        #exc_type, exc_value, exc_traceback = sys.exc_info()
        #traceback.print_exception(exc_type, exc_value, exc_traceback,2,'error_log')
        print(traceback.format_exc())
        print("error getting station "+str(station_id))
        errorfile.write(str(station_id)+'\n')


print(data)
#utils.append_csv(data,tmpdir+'data',';')

#open(tmpdir+'time'+str(taskid),'a').write(str(time.time() - start))
print('Ellapsed Time for task : '+str(taskid)+' :'+str(time.time() - start))
