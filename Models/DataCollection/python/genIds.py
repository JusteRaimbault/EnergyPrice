
import numpy,sys
import utils

nruns = int(sys.argv[1])
maxid = int(sys.argv[2])

#tmpdir = 'test/tmp/'
tmpdir='tmp'

ids = list(range(1,maxid+1))
numpy.random.shuffle(ids)

step = int(len(ids)/nruns)

for i in range(nruns):
    utils.export_array(ids[(i*step):((i+1)*step)],tmpdir+'ids'+str(i))
