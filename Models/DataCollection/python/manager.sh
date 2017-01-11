
# data collection manager

RUNNING=`ps -ef | grep "python collect.py" |grep -v "grep" |wc -l`

if [[ $RUNNING -ne 0 ]] ; then
    echo "already running"
    exit 1
fi


cd /root/ComplexSystems/EnergyPrice/Models/DataCollection/python 

# Parameters

# number of // runs
NRUNS=`cat conf/nruns`
MAXID=`cat conf/maxid`
PYTHON=`cat conf/python`

## Setup

# kill torpool
./killPool.sh

# archive previous run
./archive.sh


## Run

# run the torpool
java -jar lib/torpool.jar $NRUNS &
# wait for bootstrap
echo "sleeping "$(($NRUNS * 10))
sleep $(($NRUNS * 10))

# generate ids
$PYTHON genIds.py $NRUNS $MAXID


# run the parallel data collection
./parrunnum $PYTHON" collect.py " $NRUNS
