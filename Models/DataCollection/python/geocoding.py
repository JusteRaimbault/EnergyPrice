
from nominatim import Nominatim
import utils,functools,traceback

# read Nominatim conditions :
#  https://operations.osmfoundation.org/policies/nominatim/

nom = Nominatim()

data = utils.read_csv('test/adresses_sample.csv',';')

count=0
for line in data:
    print('Getting : '+line[1])
    raw = line[1].split(' ')
    found = False
    for i in range(2,len(raw)):
        #print(raw[0:(i-1)])
        #print(raw[i:len(raw)-1])
        str1 = functools.reduce(lambda x, y: x+y,raw[0:(i-1)])+' '+line[2]
        str2 = functools.reduce(lambda x, y: x+y,raw[i:len(raw)])+' '+line[2]
        query1 = nom.query(str1)
        query2 = nom.query(str2)
        try :
            if len(query1) > 0 :
                found=True
                print(str1+" - coords : "+str(query1[0]['lon'])+' ; '+str(query1[0]['lat']))
        except Exception :
            print(traceback.format_exc())
        try :
            if len(query2) > 0 :
                found=True
                print(str2+" - coords : "+str(query2[0]['lon'])+' ; '+str(query2[0]['lat']))
        except Exception :
            print(traceback.format_exc())
    if found :
        count=count+1

print(count/len(data))
