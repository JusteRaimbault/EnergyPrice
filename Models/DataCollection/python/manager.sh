
# data collection manager

RUNNING=`ps -ef | grep "python collect.py" |grep -v "grep" |wc -l`

if [[ $RUNNING -ne 0 ]] ; then
    echo "already running"
    exit 1
fi


# Parameters

# number of // runs
NRUNS=`cat conf/nruns`
MAXID=`cat conf/maxid`

## Setup

# kill torpool
./killpool.sh

# archive previous run
./archive.sh


## Run

# run the torpool
java -jar lib/torpool.jar $NRUNS
# wait for bootstrap
echo "sleeping "$(($NRUNS * 20))
sleep $(($NRUNS * 20))

# generate ids
python genIds.py $NRUNS $MAXID


# run the parallel data collection
./parrunnum "python collect.py " $NRUNS
