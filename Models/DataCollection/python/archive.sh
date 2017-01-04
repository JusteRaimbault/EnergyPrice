
# data archiving
DATADIR='data/'
TMPDIR='tmp/'

NRUNS=`cat conf/nruns`

# move : tmp_dir/data to datadir/timestamp_data.csv

TIMESTAMP=`cat $TMPDIR/timestamp`

cp $TMPDIR"data" $DATADIR$TIMESTAMP"_data.csv"
rm $TMPDIR"data"
# header
echo "id;fuel;price;time;user;ts" > $TMPDIR"data"

cp $TMPDIR"errors" $DATADIR$TIMESTAMP"_errors.csv"
rm $TMPDIR"errors"
cp $TMPDIR"empty" $DATADIR$TIMESTAMP"_empty.csv"
rm $TMPDIR"empty"
cp $TMPDIR"nostation" $DATADIR$TIMESTAMP"_nostation.csv"
rm $TMPDIR"nostation"

# new timestamp
echo `date "+%s"` > $TMPDIR"/timestamp"
