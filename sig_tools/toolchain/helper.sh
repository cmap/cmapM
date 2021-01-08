#!/bin/bash

#Helper functions
######################
# printHelpAndExit: Print help and quit
# Inputs:
#       variable usageHelp must exist
#       exit code
# Output:
#       prints $usageHelp and exits with exit code
######################
printHelpAndExit()
{
	echo "$usageHelp"
	exit $1
}

#######################
# printErrorHelpAndExit: Print error message, help and quit
# Inputs:
#        message to display
#        variable usageHelp must exist
# Output:
#        prints error and exits with error code 1
#######################
printErrorHelpAndExit()
{
        echo
        echo "Error: $@"
        echo
        printHelpAndExit 1
}
########################
# printErrorAndExit: Print error message and quit
# Inputs:
#        message to display
# Output:
#        prints error and exits with error code 1
########################
printErrorAndExit()
{
        echo
        echo "$@"
        echo
	exit 1
}
########################
# fileCheck: Check if file exists
# Inputs:
#       filename
# Outputs:
#       if filename does not exist, prints error and exits
########################
fileCheck()
{
 [ ! -f "$1" ] && printErrorAndExit "File:$1 missing"
}

########################
# dirCheck: Check if folder exists
# Inputs:
#       dirname
# Outputs:
#       if dirname does not exist, prints error and exits
########################
dirCheck()
{
 [ ! -d "$1" ] && printErrorAndExit "Folder:$1 missing"
}

########################
# filePath: Absolute path to a file
# Inputs: 
#       filename
# Outputs: 
#       variable FILEPATH set to absolute path of filename
########################
filePath()
{
    prg=$1
    if [ ! -e "$prg" ]; then
	case $prg in
	    (*/*) exit 1;;
	    (*) prg=$(command -v -- "$prg") || exit;;
	esac
    fi
    dir=$(
	cd -P -- "$(dirname -- "$prg")" && pwd -P
	) || exit
    FILEPATH=$dir/$(basename -- "$prg") || exit 
}
