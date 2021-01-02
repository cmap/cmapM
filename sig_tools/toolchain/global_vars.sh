#!/bin/bash

# GLOBAL VARIABLES used by many scripts

#***Change to point to the correct path(s) ***
# Path to Matlab standalone scripts
MSCRIPT_PATH=${MSCRIPT_PATH:-'/cmap/tools/sig_tools'}
# Path to Mortar library
MORTARPATH=${MORTARPATH:-'/cmap/tools/mortar'}
# Update Mortar before compilation
UPDATEMORTAR=${UPDATEMORTAR:-1}
# use version control for binary files
USE_SUBVERSION=${USE_SUBVERSION:-1}
# project name for LSF jobs
PROJECT=$USER
#*** Probably not necessary to change anything beyond this ***

# where main scripts reside
BIN_PATH=$(dirname $0)
# script to execute java xtools
RUNBIN="$BIN_PATH/run"
MCR_ROOT=$MSCRIPT_PATH/mcr/versions
# CPU Architecture
MATLAB_ARCH=glnxa64

# MATLAB specific
# Matlab version to use

# v814, R2014b, [Dev]
MATLAB_ROOT=/broad/software/nonfree/Linux/redhat_6_x86_64/pkgs/matlab_2014b
MCR_VERSION=v84

# v717, R2012a, [Stable, has h5 support]
#MATLAB_ROOT=/broad/software/nonfree/Linux/redhat_5_x86_64/pkgs/matlab_2012a
#MCR_VERSION=v717

# v713, R2011b 
#MATLAB_ROOT=/broad/software/nonfree/Linux/redhat_5_x86_64/pkgs/matlab_2011b
#MCR_VERSION=v716

# v713, R2010a 
#MATLAB_ROOT=/broad/software/nonfree/Linux/redhat_5_x86_64/pkgs/matlab_2010a
#MCR_VERSION=v713

# v714, R2010b
#MATLAB_ROOT=/broad/software/nonfree/Linux/redhat_5_x86_64/pkgs/matlab_2010b
#MCR_VERSION=v714

# v76 tested ok
#MATLAB_ROOT=/broad/tools/apps/matlab76
#MCR_VERSION=v78

# Matlab in use
#MATLAB_ROOT=$(which matlab|sed 's_/bin/matlab$__')
#MATLAB_ROOT=/broad/tools/apps/matlab2009b

# setup build environment for Matlab
MCC_BUILD_ENV="$BIN_PATH/setup_mcc_env.sh"
# setup runtime environment
MCR_ENV="$BIN_PATH/setup_mcr_env.sh"

# script to execute Matlab binaries
RUMBIN="$BIN_PATH/rum"
# logs for Matlab scripts 
MSCRIPT_LOG_PATH="$MSCRIPT_PATH/logs"

# Path to GCC, needed by mcc
# tested ok for 2013a, v810
#GCC_PATH=/broad/software/free/Linux/redhat_5_x86_64/pkgs/gcc_4.7.2
# tested ok for 2012a, v717
GCC_PATH=/broad/software/free/Linux/redhat_5_x86_64/pkgs/gcc_4.4.4/
#tested ok for 2010a, v713
#GCC_PATH=/broad/software/free/Linux/redhat_5_x86_64/pkgs/gcc_4.2.3/
# tested ok for 7.6
#GCC_PATH=/util/gcc-4.1.1


