# 
# This scripts assumes you have curl, awk, sed and a basic bourne shell environment.
# if you are running on a windows environment you may need to download the Git Bash Window (https://git-scm.com/download/win)
#

unix command line to export a SFDC report to CSV (username more be Classic Mode NOT Lightning)
**Note:** you will need to unzip **csvdiff_exe.zip** in same directory level (WINDOWS ONLY)

 **Introduction**

This script allows you to easily export SFDC reports to CSV by using the command line, and standard tools like curl, awk, sed, etc.
Most errors encountered are associated with an issue with user-id or password+securityToken (PasswordSecurityToken)

**NOTE**: Should you encounter issues, more than likely stem from an invalid UID and/or Password+SecurityToken; the latter being more dominant.

**PROCESS**


1. curl to call the SFDC API login entrypoint
2. sed to parse the SOAP response
3. curl to export the report to CSV
4. save the report into appropriate directory (Pre or Post)

**USAGE**

usage: reports <-pre|-post|-c|-s> [-ip]  [-h]

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
	
**EXAMPLES**:

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
		
		
**NOTES**:
    This script expects 2 files to have been created:
	 1) sf_login.txt   : This file contains the users UID and PWD+SecurityToken information; sample already present "sf_login_sample.txt"
	 2) reportsIds.txt : This file contains the report IDs [one per line]

	The downloaded utility is for Windows. However, more information can be found below ( as it is a perl script)
    Compare Utility is found here http://csvdiff.sourceforge.net/
