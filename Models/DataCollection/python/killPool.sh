ps -ef | grep "tor --SOCKSPort" |grep -v 'tor --SOCKSPort 904[0-9]' | grep -v grep | awk -F" " '{print "kill -9 "$2}' | sh
ps -ef | grep "java -jar lib/torpool.jar" |grep -v "java -jar lib/torpool.jar 5 9040" |grep -v grep | awk -F" " '{print "kill -9 "$2}' | sh

