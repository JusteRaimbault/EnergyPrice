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
