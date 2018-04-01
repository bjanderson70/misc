#!/bin/sh -x
#--------------------------------------------------------
# AUTHOR: Salesforce
# DESCRIPTION:
# This script pulls the user's session ID. It assumes
# the user properly set the 'sf_login.txt' information,
# which includes:
#      <UID>       : User Name
#      <PWD+TOKEN> : Password + Security Token
#
# The results are saved in '.sf_results' file
#--------------------------------------------------------

#
# How to use the script
#
usage() {
  
[ "$1" ] && echo 1>&2 "Info: $1" ; echo 1>&2 \
'
usage: getSID <true|false>

OPTIONS:
		true     : is a Sandbox
		false    : is not a Sandbox 
'
exit 2;
}

[ "$1" ] || usage "is Sandbox is expected"

if [ ! -s sf_login.txt ] 
then
	echo "    Missing the 'sf_login.txt' file"
	exit 2;
fi

if test "$1" == 'true'; then
	echo "    Getting SID from a Sandbox... [results found in .sf_results]..."
	curl -f -s -X POST https://test.salesforce.com/services/Soap/u/41.0 -H "Content-Type: text/xml; charset=UTF-8" -H "SOAPAction: login" -d @sf_login.txt > ./.sf_results
else
	echo "    Getting SID from Production... [results found in .sf_results]..."
	curl -f -s -X POST https://login.salesforce.com/services/Soap/u/41.0 -H "Content-Type: text/xml; charset=UTF-8" -H "SOAPAction: login" -d @sf_login.txt > ./.sf_results
fi
exit $?;
