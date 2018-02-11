mkdir pdata
ls data | grep "_data" |awk '{print "cat data/"$0" |grep \";\" > pdata/"$0}'|sh
zip -r data.zip pdata
rm -rf pdata

