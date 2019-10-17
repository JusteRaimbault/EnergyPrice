import json

# too lazy to use pandas
usdata=list()
candata=list()

for stateid in range(1,52):
    currentdata = json.load(open("states/"+str(300000+stateid)+".json",'r'))
    #print(currentdata[0].keys())
    #print("US:"+str(currentdata[0]['USList'][0:2]))
    #print("CAN:"+str(currentdata[0]['CANList'][0:2]))
    for usrec in currentdata[0]['USList']:
        usdata.append([str(stateid),usrec['datetime'],usrec['price']])
    for canrec in currentdata[0]['CANList']:
        candata.append([str(stateid),canrec['datetime'],canrec['price']])

# write to csv
filewriter = open('states/USStates.csv','w')
filewriter.write("stateid,date,price\n")
for usrec in usdata:
    filewriter.write(str(usrec[0])+","+str(usrec[1])+","+str(usrec[2])+"\n")
filewriter.close()

filewriter = open('states/CANStates.csv','w')
filewriter.write("stateid,date,price\n")
for canrec in candata:
    filewriter.write(str(canrec[0])+","+str(canrec[1])+","+str(canrec[2])+"\n")
filewriter.close()
