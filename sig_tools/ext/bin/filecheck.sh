#!/bin/bash

# Mortar file checker
# Checks for duplicates and name clashes
# Print code statistics
# 10/20/2010, Rajiv Narayan [narayan@broadinstitute.org]

SELF_DIR=$(dirname $0)
BINDIR=$SELF_DIR/..
TARGET_DIR=$SELF_DIR/../..

echo "Checking for duplicate files:"
echo "----------------------------"
$BINDIR/fslint-2.42/fslint/findup $TARGET_DIR \( -path "*/.git" -o -path "*/ext" -o -path "*/doc" \) -prune -o --summary -name '*.m' 

#Name clashes
echo
echo "Checking for name clashes:"
echo "-------------------------"
$BINDIR/fslint-2.42/fslint/findsn $TARGET_DIR \( -path "*/.git" -o -path "*/doc" \) -prune -o -C -name '*.m'

echo
echo "Checking for temporary files:"
echo "-------------------------"
$BINDIR/fslint-2.42/fslint/findtf $TARGET_DIR \( -path "*/.git" -o -path "*/doc" \) -prune -o 

#Stats
echo
echo "Statistics:"
echo "----------"
#$BINDIR/cloc-1.52.pl ../ --match-f='\.m$' --progress-rate=0 --quiet
$BINDIR/bin/cloc-1.52.pl $TARGET_DIR --exclude-dir=ext --match-f='\.m$' --progress-rate=0 --quiet  --csv|grep 'MATLAB'|awk 'BEGIN{FS=","}{print "Matlab files:",$1,"\nBlank lines:",$3,"\nComments:",$4,"\nLines of code:",$5}'

# use cloc for stats instead
#fc=0
#lc=0
#rlc=0
#for f in $(find ../ -name '*.m'); do
#    rl=$(wc -l "$f"|awk '{print $1}')
#    l=$(egrep -v '%|^$' "$f"|wc -l)
#    fc=$[$fc + 1]
#    lc=$[$lc + $l]
#    rlc=$[$rlc + $rl]
#done
#echo "Number of M-files: $fc"
#echo "Total lines of code [includes blank and comment lines]: $rlc"
#echo "Lines of code: $lc"
