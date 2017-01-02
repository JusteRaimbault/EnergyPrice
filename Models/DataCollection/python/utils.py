# utils


##
#
def read_csv(filename,delimiter):
    res = []
    for line in open(filename).readlines():
        currentrow = line.replace('\n','').split(delimiter)
        if len(currentrow)==1 :
            res.append(currentrow[0])
        else:
            res.append(currentrow)
    return(res)


def append_csv(data,filename,delimiter):
    f = open(filename,'a')
    for row in data :
        for c in range(len(row)) :
            f.write(str(row[c]))
            if c < len(row)-1 :
                f.write(delimiter)
            else :
                f.write('\n')
    f.close()



def export_array(data,filename):
    f = open(filename,'w')
    for d in data :
        f.write(str(d)+'\n')
    f.close()
