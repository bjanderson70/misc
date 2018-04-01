#!/bin/sh
echo "#!/bin/sh" > runConvert.sh
awk -F',' 'NR>1 { gsub(/^[ \t]+|[ \t]+$/, "",$1);gsub(/\//,"",$3);gsub(/^[ \t]+/,"",$3);print "cp -f "$1 ".csv" " \""$3".csv""\""}' Manifest.txt >> runConvert.sh
./runConvert.sh
rm -f ./runConvert.sh
