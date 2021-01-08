#!/bin/bash

# Set within Jenkins job
# export MORTARPATH=/cmap/tools/jenkins/mortar
# Skip updating since build takes care of that
export UPDATEMORTAR=0
# Output path
export MSCRIPT_PATH=/cmap/tools/sig_tools
# Dont check in binary
export USE_SUBVERSION=0
# Matlab path and MCR version
export MATLAB_ROOT='/broad/software/nonfree/Linux/redhat_6_x86_64/pkgs/matlab_2014b'
export MCR_VERSION='v84'
export VDBPATH='/cmap/data/vdb'
