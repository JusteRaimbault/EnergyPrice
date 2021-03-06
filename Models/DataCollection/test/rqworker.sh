
TASKNUM=$1
TASKID=$2

idmax=192100
#idmax=200
outfile="data/test_all_2.csv"
#outfile="data/test2.csv"
port=$((9050 + $TASKID))

start=`date +'%s'`

for i in `seq $(($TASKID + 1)) $TASKNUM $idmax`
do
  curl -s --socks5-hostname 127.0.0.1:$port  www.gasbuddy.com/Station/$i > html/tmp$TASKID
  n=`cat html/tmp$TASKID | grep "price-display credit-price" | wc -l`
  station=`cat html/tmp$TASKID | grep "station-address" | wc -l`
  #echo "station $i : $n prices ; station : $station"
  echo "$i;$station;$n" >> $outfile
done

end=`date +'%s'`

t=$(($end - $start))
echo "Task $TASKID - time ellapsed : $t s"
