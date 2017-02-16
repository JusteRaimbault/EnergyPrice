ps -ef | grep "tor --SOCKSPort" |grep -v "tor --SOCKSPort 9049" | grep -v grep | awk -F" " '{print "kill -9 "$2}' | sh
ps -ef | grep "java -jar lib/torpool.jar" | grep -v grep | awk -F" " '{print "kill -9 "$2}' | sh

