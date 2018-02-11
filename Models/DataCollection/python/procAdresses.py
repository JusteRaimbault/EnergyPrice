

adresses_file = 'loc/adresses.csv'


#dico = {}
#with open(adresses_file) as f:
#    for linestr in f:
#        line = linestr.replace('\n','').split(';')
#        for word in line[1].replace('  ',' ').split(' '):
#            if not word in dico : dico[word] = 1
#            dico[word] = dico[word] + 1
#
#sorted_words = sorted(dico.items(), key=lambda entry: entry[1],reverse=True)
#
#for i in range(30):
#    print(sorted_words[i])
#


####
# adress splitting



# adress markers
markers =  ['St','Rd','Ave','Dr','Blvd','Hwy','Ln','Pkwy','Way']

lengths = []
count = 0;firstpos = 0;sndpos = 0;without = 0;firstcount=0;sndcount=0
with open(adresses_file) as f:
    for linestr in f:
        line = linestr.replace('\n','').split(';')
        #print(line)
        #print(addr_search_query(line,markers))
#         pos = []
#         for marker in markers :
#             ind = line[1].find(marker)
#             if ind != -1 : pos.append(ind/len(line[1]))
#         lengths.append(len(pos))
#         if len(pos)>0 :
#             firstpos = firstpos + sorted(pos)[0]
#             firstcount = firstcount + 1
#             if len(pos)>1 :
#                 sndpos = sndpos + sorted(pos)[1]
#                 sndcount = sndcount + 1
#                 if len(pos) > 2 :
#                     print(line[1])
#         else :
#             without = without + 1
#             #print(line[1])
#         count = count + 1
#
# print('max length : '+str(max(lengths)))
# print('mean length : '+str(sum(lengths)/len(lengths)))
# print('without marker : '+str(without/count))
# print('one : '+str((firstcount-sndcount)/count))
# print('two and more : '+str(sndcount/count))
# print('mean first rel pos : '+str(firstpos/firstcount))
# print('mean snd rel pos : '+str(sndpos/sndcount))

#  for  ['St ','Rd ','Ave ','Dr ','Blvd ','Hwy ','Ln ','Pkwy ','Way ']
#max length : 3
#mean length : 0.8654768938138536
#without marker : 0.1797267893424788
#one : 0.7753937490093231
#two and more : 0.044879461648198046
#mean first rel pos : 0.49350201031956015
#mean snd rel pos : 0.7837160152856258
