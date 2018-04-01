#!/bin/sh
#--------------------------------------------------------
# AUTHOR: Salesforce
# DESCRIPTION:
#
# Processes reports (CSV saved reports). For more clarity
# run the command with a "-h" option for syntax and examples
#
# Note: If needed for debugging, add -x to the end [line 1] (i.e.#!/bin/sh -x )
#
#--------------------------------------------------------

#
# how to use this script
#
usage() {
  
[ "$1" ] && echo 1>&2 "Info: $1" ; echo 1>&2 \
'
usage: processReports <Report-Id> <Directory>

OPTIONS:
    <Report-Id> : The report Id from the file
	<Directory> : The directory to write the files to Pre or Post
'
exit 2
}

[ "$1" ] || usage "Report Id expected"
[ "$2" ] || usage "Directory expected"

# variable setup
rpt=$1;
dir=$2;
# create directory (once), if not already created
mkdir -p $dir

# get the session id
sid=`sed -n '/sessionId/{s/.*<sessionId>//;s/<\/sessionId.*//;p;}' < ./.sf_results`
# get the server url (append salesforce.com)
server=`sed -n '/serverUrl/{s/.*<serverUrl>//;s/salesforce.com.*//;p;}' < ./.sf_results`"salesforce.com"

# validate that we can get the report id
curl -s "$server/$rpt" -b "sid=$sid" -I -w '%{http_code}' | [ $(tail -1) = '404' ] && usage 'unable to render the SFDC report'
# get the csv (report)
curl -f -s "$server/$rpt?export=1&enc=UTF-8&xf=csv" -b "sid=$sid" > temp_csv.csv
# determine the # lines we pulled from the report
lines=`wc -l temp_csv.csv | awk '{print $1;}'`;
#any data
if test "$lines" != "0" 
then
	# we now remove the last 3 lines, get that location
	start=`expr $lines - 3`;
	# trim the lines at the end of the report
	sed  "${start},${lines}d" temp_csv.csv >  temp_upd_csv.csv
	# get the report name
	filename=`tail -1 temp_upd_csv.csv | sed "s/\"//g"`;
	#name="$rpt"_"$filename"".csv"
	name="$rpt.csv"
	# copy the temp name over to the report name
	cp temp_upd_csv.csv "$dir/$name"
	echo "    Report Id, $rpt (report name '$filename') copied to directory '$dir/$name'"
	echo "$rpt  , $lines ,  $filename" >> "$dir/Manifest.txt"
else
	echo "    0 length line for $rpt"
fi
# clean-up
rm -rf temp_upd_csv.csv temp_csv.csv
exit 0
