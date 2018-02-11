
import functools,traceback,os,sys,time,requests
#from nominatim import Nominatim
import utils

# read Nominatim conditions :
#  https://operations.osmfoundation.org/policies/nominatim/
# -> must wait 1sec between requests ; needs to use a torpool for efficiency
#

adresses_file = 'loc/adresses.csv'
locdir = 'loc'
nports = 5

startingport = int(sys.argv[1])
proxies = []
for i in range(nports) :
    proxies.append({'http':'socks5://localhost:'+str(startingport+i)})

#data = utils.read_csv('test/adresses_sample.csv',';')


existing = set()
if os.path.isfile(locdir+'/coordinates.csv'):
    for line in utils.read_csv(locdir+'/coordinates.csv',';'):
        if len(line)>1 :
            existing.add(line[0])

print('existing coords : '+str(len(existing)))

nocoords = set()
if os.path.isfile(locdir+'/nocoordinates.csv'):
    for line in utils.read_csv(locdir+'/nocoordinates.csv',';'):
        if len(line)>1 :
            nocoords.add(line[0])

print('no coords : '+str(len(nocoords)))


def addr_search_query(line,markers):
    addr=line[1].replace(' N ',' ').replace(' S ',' ').replace(' E ',' ').replace(' W ',' ')
    pos = []
    for marker in markers :
        ind = addr.find(marker)
        if ind != -1 :
            pos.append([marker,ind/len(addr)])
    sorted_pos = sorted(pos, key=lambda entry: entry[1])

    prefix = ''
    if len(sorted_pos)<2 :
        prefix = addr
    else :
        markerind = 0
        if sorted_pos[0][1] < 0.3 : markerind = 1
        prefix = addr.split(sorted_pos[markerind][0])[0]+sorted_pos[markerind][0]

    #return(prefix)
    return(prefix+' '+line[2]+' '+line[3])


markers =  ['St','Rd','Ave','Dr','Blvd','Hwy','Ln','Pkwy','Way']


count=0
j=0
with open(adresses_file) as f:
    for linestr in f:
        line = linestr.replace('\n','').split(';')
        if line[0] not in existing and line[0] not in nocoords :
            print('Getting station '+line[0]+' - address : '+line[1]+' '+line[2]+' '+line[3])
            #raw = line[1].split(' ')
            querystring = addr_search_query(line,markers)
            #print(querystring)
            query = requests.get('http://nominatim.openstreetmap.org/search',params = {'format':'json','q':querystring},proxies=proxies[j%nports])
            res = query.json()
            try :
                if len(res) > 0 :
                    print(querystring+" - coords : "+str(res[0]['lat'])+' ; '+str(res[0]['lon']));print('')
                    utils.append_csv([[line[0],querystring,str(res[0]['lat']),str(res[0]['lon'])]],locdir+'/coordinates.csv',';')
                    count=count+1
                else :
                    utils.append_csv([[line[0],querystring]],locdir+'/nocoordinates.csv',';')
            except Exception :
                print(traceback.format_exc())

            j=j+1
            time.sleep(1.0/nports)



print(count/j)



        #for i in range(2,len(raw)):
            #str1 = functools.reduce(lambda x, y: x+' '+y,raw[0:(i-1)])+' '+line[2]+' '+line[3]+' '+line[4]
            #str2 = functools.reduce(lambda x, y: x+' '+y,raw[i:len(raw)])+' '+line[2]
            #query1 = nom.query(str1)
            #query2 = nom.query(str2)

        #    query1 = requests.get('http://nominatim.openstreetmap.org/search',params = {'format':'json','q':str1})
    #        res1 = query1.json()
    #        time.sleep(1.0)
            #query2 = requests.get('http://nominatim.openstreetmap.org/search',params = {'format':'json','q':str2})
            #res2 = query2.json()
            #try :
            #    if len(res1) > 0 :
            #        found=True
            #        print(str1+" - coords : "+str(res1[0]['lat'])+' ; '+str(res1[0]['lon']))
            #except Exception :
            #        print(traceback.format_exc())
            #try :
            #    if len(res2) > 0 :
            #        found=True
            #        print(str2+" - coords : "+str(res2[0]['lon'])+' ; '+str(res2[0]['lat']))
            #except Exception :
            #    print(traceback.format_exc())
