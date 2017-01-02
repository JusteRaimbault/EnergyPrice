ps -ef | grep `which tor` | grep -v grep | awk -F" " '{print "kill -9 "$2}' | sh
