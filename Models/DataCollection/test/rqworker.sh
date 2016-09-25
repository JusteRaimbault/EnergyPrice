
TASKID=$1

idmax=100
outfile="data/test.csv"
port=$((9050 + $TASKID))

start=`date +'%s'`

for i in `seq $TASKID $idmax`
do
  curl -s --socks5-hostname 127.0.0.1:$port  www.gasbuddy.com/Station/$i > html/tmp$TASKID
  n=`cat html/tmp | grep "price-display credit-price" | wc -l`
  station=`cat html/tmp | grep "station-address" | wc -l`
  #echo "station $i : $n prices ; station : $station"
  echo "$i;$station;$n" >> $outfile
done

end=`date +'%s'`

t=$(($end - $start))
echo "Task $TASKID - time ellapsed : $t s"

