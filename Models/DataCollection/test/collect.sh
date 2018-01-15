
rm -rf states
mkdir states

for n in `seq 300001 300051`
do
    echo $n
    ./request.sh $n states/$n.json
done

