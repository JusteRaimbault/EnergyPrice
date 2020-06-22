

def read(filename):
    """
    Read single line file
    """
    return(open(filename,'r').readlines()[0].replace('\n',''))


def import_csv(csvfile,delimiter,header=True):
    infile = open(csvfile,'r')
    res = []
    line=0
    for line in infile.readlines():
        if not header or line > 0:
            if line[0]!="#" :
                res.append(line.replace('\n','').split(delimiter))
        line = line + 1
    return(res)
