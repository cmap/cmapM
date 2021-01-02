#!/bin/bash
# Setup Build environment for compiling matlab scripts at Broad

# These settings work with versions 7.2, 7.3
# Set in global_vars.sh
# MATLAB_ROOT=/broad/tools/apps/matlab7.2
# MATLAB_ROOT=/broad/tools/apps/matlab73
# MATLAB_ROOT=/broad/tools/apps/matlab76
source $(dirname $0)/global_vars.sh
echo "Using Mortar: $MORTARPATH"
#update Mortar
if [ $UPDATEMORTAR -eq 1 ]; then
    echo "Updating Mortar..."
    (cd $MORTARPATH; git pull)
fi
# add mortar to includes
MCC_INCLUDE=$(find $MORTARPATH -type d|egrep -v '\.git|mortar/doc|mortar/ext|mortar/tools|tests|templates|resources|\+mortar|node_modules|\+work|scratch|mortar/js'| sed  's/^/-I /')
# add yaml parser
MCC_INCLUDE="$MCC_INCLUDE -I $MORTARPATH/ext/yamlmatlab"
MCC_INCLUDE="$MCC_INCLUDE -I $MORTARPATH/ext/jsonlab"
MCC_INCLUDE="$MCC_INCLUDE -I $MORTARPATH/tests"

# Add resources to CTF archive
MCC_ADD="-a $MORTARPATH/resources \
-a $MORTARPATH/mongo-matlab-driver \
-a $MORTARPATH/ext/bin \
-a $MORTARPATH/ext/bh_tsne \
-a $MORTARPATH/ext/smi2fp \
-a $MORTARPATH/ext/jars \
-a $MORTARPATH/templates \
-a $MORTARPATH/tests/assets \
-a $MORTARPATH/tests"

# Matlab76 requires gcc >= 4.0.0 and <= 4.2.0 
# Prepend /util/gcc-4.1.1/bin to PATH and
# /util/gcc-4.1.1/lib64:/util/gcc-4.1.1/lib to LD_LIBRARY_PATH

# configure the "dotkit" environment maintenance system
#eval `/broad/tools/dotkit/init`
#use gcc-4.3.0

export MATLAB_ROOT=$MATLAB_ROOT
export MATLAB_ARCH=$MATLAB_ARCH
export PATH=$GCC_PATH/bin:$PATH

# Java runtime for the selected Matlab
#JREFULL=$(find $MATLAB_ROOT/sys/java/jre/$MATLAB_ARCH/ -name 'jre*' -type d)
#JRE=$(basename $JREFULL)
# export LD_LIBRARY_PATH=$GCC_PATH/lib64:$GCC_PATH/lib:\
# $LD_LIBRARY_PATH:\
# $MATLAB_ROOT/sys/os/$MATLAB_ARCH:\
# $MATLAB_ROOT/bin/$MATLAB_ARCH:\
# $MATLAB_ROOT/sys/java/jre/$MATLAB_ARCH/$JRE/lib/i386/native_threads:\
# $MATLAB_ROOT/sys/java/jre$MATLAB_ARCH/$JRE/lib/i386/client:\
# $MATLAB_ROOT/sys/java/jre/$MATLAB_ARCH/$JRE/lib/i386
# export XAPPLRESDIR=$MATLAB_ROOT/X11/app-defaults

LD_LIBRARY_PATH=.:${MATLAB_ROOT}/runtime/$MATLAB_ARCH ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MATLAB_ROOT}/bin/$MATLAB_ARCH ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MATLAB_ROOT}/sys/os/$MATLAB_ARCH;
MCRJRE=$(find $MATLAB_ROOT/sys/java/jre/$MATLAB_ARCH/ -name 'jre' -type d)
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads ; 
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE} ;  
XAPPLRESDIR=${MATLAB_ROOT}/X11/app-defaults ;
export LD_LIBRARY_PATH;
export XAPPLRESDIR;
