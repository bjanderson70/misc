#!/bin/sh
#--------------------------------------------------------
# AUTHOR: Salesforce
# DESCRIPTION:
# Iterate over the reports (CSV saved reports). For more clarity
# run the command with a "-h" option for syntax and examples
#
#
# Note: If needed for debugging, add -x to the end [line 1] (i.e.#!/bin/sh -x )
#
# Compare Utility is found here http://csvdiff.sourceforge.net/
#
#--------------------------------------------------------
MARGIN_OF_ERROR=6;
#RED='\033[0;31m'
RED='\033[1;31m'
NC='\033[0m' # No Color
YELLOW='\033[0;33m'       # Yellow
GREEN='\033[0;32m'        # Green
BLUE='\033[0;34m'         # Blue
#
# How to use
#
usage() {
  
[ "$1" ] && echo 1>&2 "Info: $1" ; echo 1>&2 \
'
usage: reports [-pre|-post|-c|-s] [-ip]  [-h]

OPTIONS:
    <process-type> : The process type [-pre | -post | -c | -s]
			-pre   : Pre process work , pull down the reports prior to migration
			-post  : Post process work , pull down the reports after migration
			-c     : Compare Pre and Post process work
			-s     : Show what report Ids would be pulled
	<Sandbox-or-Production>
			-ip    : is Production Org (if not present, will assume Sandbox)
	<misc-options>
			-h     : This text
	
EXAMPLES:

	(1) To pull reports from PRODUCTION (Pre-Migration) and place the results into a directory "Pre"
		$ reports -pre -ip
		
	(2) To pull reports from SANDBOX (Pre-Migration) and place the results into a directory "Pre"
		$ reports -pre
		
	(3) To pull reports from PRODUCTION (Post-Migration) and place the results into a directory "Post"
		$ reports -post -ip

	(4) To SHOW which report Ids from PRODUCTION will be process (NO Directories are created)
		$ reports -s -ip

	(5) To Compare reports in "Pre" and "Post" directories. This assumes each found Report Id in "Pre" will be in "Post" and place
	    results in "Compare" directory
		$ reports -c

	(6) This text
		$ reports -h
		
		
NOTES:
    This script expects 2 files to have been created:
	 1) sf_login.txt   : This file contains the users UID and PWD+Token information; sample already present "sf_login_sample.txt"
	 2) reportsIds.txt : This file contains the report IDs [one per line]
'
exit 1;
} # end of usage
#
# Iterate over the reports ids in 'reportIds.txt'.
# Calls 'processReports.sh' to process the report data (CSV).
# The data will be placed in a directory 'Pre' or 'Post'
#
getReports(){
	processType=$1;
	# report Ids found ?
	if [ ! -s reportIds.txt ]
	then
		echo -e "${YELLOW}    Warning: Expected Report Ids in file 'reportIds.txt' [1 per line]; none were found ${NC}"
		exit 3;
	fi
	echo "    ----------------------- START --------------------------"
	# perform either Pre or Post
	if test "$processType" != 'Show'; then 
		mkdir -p "$processType"
		echo "    Creating a Manifest.txt file in directory '$processType'"
		echo "Report Id  , Line Count , Name " > "$processType/Manifest.txt"
	fi
	count=0;
	#
	# iterate over the ids
	for mLine in `cat reportIds.txt |tr -d '\r'`
	do
		count=`expr $count + 1`;
		echo "    $count) Getting report information from Id $mLine ($processType) ..."
		
		if [ -z "$mLine" ]
		then
			echo -e "${YELLOW}    No report information found for id : $mLine ${NC}"
		else
			if test "$processType" != 'Show'; then
				./processReports.sh "$mLine" "$processType"
			fi     
		fi
		echo "    ------------------------------------------------------"
	done
	echo "    ----------------------- DONE --------------------------"
} # end of getReports
#
# Now Compare the Manifests with record count and names
# 
compareManifests() {
	fileTo="Manifest_Compare.txt" 
	#
	echo "    ----------------------- START Compare of Manifests --------------------------"
    echo ""
	echo "    Compare Manifests (record size and names ) of Pre and Post directories [compare Pre/Manifest.txt Post/Manifest.txt]..."
	echo ""
	./csvdiff_exe/bin/csvdiff.exe  -t -l -i -I -g -e "Pre/Manifest.txt" -a "Post/Manifest.txt" -c "./.ManifestHeader.txt"  > "$fileTo"  2>&1 || echo "    Compare Manifests command not working in this environment!"
	lines=`wc -l $fileTo| awk '{print $1;}'`;
	# if more lines found incompatible then flag; otherwise, move on storing results
	if test $lines -gt 0 ; then
		echo -e "${RED}      **** Need to visually check($fileTo) ... ${NC}"
	    cat "$fileTo" 
		sleep 2;
	fi
	echo ""
	echo "    -----------------------  DONE Compare of Manifests --------------------------"
}
#
# Iterate over the reports ids in 'reportIds.txt'.
# Calls 'processReports.sh' to process the report data (CSV).
# The data will be placed in a directory 'Pre' or 'Post'
#
compareCSVs(){
	processType=$1;
	
	RPT_TO_CHK="$processType/ReportIdsToVisuallyCheck.txt"
	RPT_IDS_NF="$processType/ReportIdsNotFound.txt"
	# report Ids found ?
	if [ ! -s reportIds.txt ]
	then
		echo -e "${YELLOW}    Warning: Expected Report Ids in file 'reportIds.txt' [1 per line]; none were found ${NC}"
		exit 3;
	fi
	echo "    ----------------------- START --------------------------"
	# performing a Compare
	if test "$processType" == 'Compare'; then 
		echo "    Results are stored in '$processType' directory ..."
		mkdir -p "$processType"
		rm -rf "$RPT_TO_CHK" "$RPT_IDS_NF"
		# compare manifest files
		compareManifests
	else
		exit -2
	fi
	count=0;
	#
	# iterate over the ids
	for mLine in `cat reportIds.txt |tr -d '\r'`
	do
		
		if [ -z "$mLine" ]
		then
			echo "    No report information found for id : $mLine"
		else
			if test "$processType" == 'Compare'; then
				count=`expr $count + 1`;
		
				if [ -d "Pre" ] && [ -d "Post" ] && [ -s "Pre/$mLine.csv" ] && [ -s "Post/$mLine.csv" ]; then
				
					echo "$count)    Comparing 'Post/$mLine.csv' to 'Pre/$mLine.csv' ..."
					fileTo="$processType/$mLine""_result.txt" 
					colFile="$processType/$mLine""_columns.txt"
					# getting the columns ( help on debug if differences)
					head -1 "Pre/$mLine.csv" > $colFile
					# find differences
					./csvdiff_exe/bin/csvdiff.exe  -t -l -i -I -g -e "Pre/$mLine.csv" -a "Post/$mLine.csv" -c "$colFile" > "$fileTo"  2>&1 || echo -e "${RED}    Compare command not working in this environment! ${NC}"
					lines=`wc -l $fileTo| awk '{print $1;}'`;
					# if more lines found incompatible then flag; otherwise, move on storing results
					if test $lines -lt $MARGIN_OF_ERROR ; then
					    echo ">>> Post/$mLine.csv is considered equal to Pre/$mLine.csv " >> "$fileTo" 
					else
						echo -e "${RED}      **** Need to visually check Report Id ($mLine) [$lines] **** ... ${NC}"
					    echo "*** Differences are found Post/$mLine.csv and Pre/$mLine.csv " >> "$fileTo" 
						echo "**********Compare results of Report ID: $mLine **********" >> "$RPT_TO_CHK"
						echo "-----------------------------------------------------------" >> "$RPT_TO_CHK"
						cat "$fileTo" >> "$RPT_TO_CHK"
						sleep 2;
					fi
					rm $colFile
				else
					echo -e "${YELLOW}$count)    Warning: Expected both 'Pre' and 'Post' directory to contain report ID: '$mLine' [Skipping]... ${NC}"
					echo "$mLine" >> "$RPT_IDS_NF"
				fi
			fi     
		fi
		echo "    ------------------------------------------------------"
	done
	echo "    ----------------------- DONE --------------------------"
} # end of compareCSVs

[ "$1" ] || usage "Process-Type expected"

# parse the command line
processType='Show'
isSandbox='true';

while [ "$#" -gt 0 ] ; do
  case "$1" in
    -pre) processType='Pre';;
      
    -post) processType='Post';;
       
    -c) processType='Compare';;
        
	-s) processType='Show';;
        
	-ip) isSandbox='false';;
       
	-h) echo '
		The script will create a Pre,Post and Compare directory for the reports pulled down from the Salesforce Org.
		These reports will then be compared. It is assumed the reports in Pre directory are the same in Post directory.
		'
		usage 'help'
        exit 1;;
    -*) usage "$1: invalid option";;
    
     *) [ "$#" -eq 0 ] || usage 'too many arguments'
  esac
  shift
done

# get the session id information if NOT comparing
if test "$processType" != 'Compare'; then
	echo "    Getting session id ..."
	./getSID.sh "$isSandbox"

	#
	# did we have issues with getting the session ID?
	if test $? -ne 0 ; then
		echo -e "${RED}    *** Error encountered trying to get a session ID. Check the User Id and/or Password+SecurityToken in 'sf_login.txt' or internet connection. ${NC}"
		exit 2;
	fi
fi
#
# process the work
#
if test "$processType" != 'Compare'; then
	# pulling reports
	getReports "$processType"
else
	# comparing reports
	compareCSVs "$processType"
fi
exit 0;