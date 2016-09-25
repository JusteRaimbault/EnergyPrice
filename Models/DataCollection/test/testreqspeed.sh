
# last station at Dim 25 sep 2016 15:20:24 CEST : 192007

start=`date +'%s'`

for i in `seq 1 400`
do
  curl -s --socks5-hostname 127.0.0.1:9050  www.gasbuddy.com/Station/$i > html/tmp
  n=`cat html/tmp | grep "price-display credit-price" | wc -l`
  station=`cat html/tmp | grep "station-address" | wc -l`
  echo "station $i : $n prices ; station : $station"
done

end=`date +'%s'`

t=$(($end - $start))
echo "Time ellapsed : $t s"

