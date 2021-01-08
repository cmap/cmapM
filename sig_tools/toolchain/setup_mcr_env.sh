#!/bin/bash
# Setup environment for executing standalone matlab scripts

echo "Setting MCR_ROOT to $MCR_ROOT"
export MATLAB_ROOT=$MCR_ROOT/$MCR_VERSION
export MATLAB_ARCH=glnxa64

# Not needed for newer scripts, 7/17 (RN)

# # Java runtime for the selected Matlab
# JREFULL=$(find $MATLAB_ROOT/sys/java/jre/$MATLAB_ARCH/ -name 'jre*' -type d)
# JRE=$(basename $JREFULL)

# export PATH=$GCC_PATH/bin:$PATH
# export LD_LIBRARY_PATH=$GCC_PATH/lib64:$GCC_PATH/lib:\
# $LD_LIBRARY_PATH:\
# $MATLAB_ROOT/sys/os/$MATLAB_ARCH:\
# $MATLAB_ROOT/bin/$MATLAB_ARCH:\
# $MATLAB_ROOT/sys/java/jre/$MATLAB_ARCH/$JRE/lib/i386/native_threads:\
# $MATLAB_ROOT/sys/java/jre$MATLAB_ARCH/$JRE/lib/i386/client:\
# $MATLAB_ROOT/sys/java/jre/$MATLAB_ARCH/$JRE/lib/i386

# export XAPPLRESDIR=$MATLAB_ROOT/X11/app-defaults
