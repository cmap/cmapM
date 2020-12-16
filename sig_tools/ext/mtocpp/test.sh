#!/bin/bash

function doit() {
  SUFFIX=$1;
  for MFILE in $FILES
  do
      echo "Checking $MFILE ..."
      MBFILE=`basename $MFILE`
      CCFILE="${MBFILE%.m}${SUFFIX}.cc"
      CCREFFILE="${MBFILE%.m}${SUFFIX}_ref.cc"
      DIFFFILE="${MBFILE%.m}${SUFFIX}.diff"
      $MTOCPP $MFILE conf$SUFFIX > $CCFILE
      if diff --strip-trailing-cr -u $CCFILE $CCREFFILE > $DIFFFILE
      then
          echo " (passed)"
          rm $DIFFFILE
      else
          echo " (failed)"
      fi
  done
}

FILES="test/+grid/+rect/@rectgrid/*.m test/+grid/+rect/doxygen_in_namespace.m ./*.m"

cd /Users/narayan/workspace/mortar/ext/mtocpp/test

if [ -x /Users/narayan/workspace/mortar/ext/mtocpp/mtocpp ];
then
    MTOCPP=/Users/narayan/workspace/mortar/ext/mtocpp/mtocpp
else
    MTOCPP="wine /Users/narayan/workspace/mortar/ext/mtocpp/mtocpp.exe"
fi

doit ""
doit "2"
