#!/bin/bash

#export LD_LIBRARY_PATH=/broad/software/free/Linux/redhat_6_x86_64/pkgs/gcc_5.1.0/lib64/libstdc++.so.6:$LD_LIBRARY_PATH
#echo $LD_LIBRARY_PATH

#eval `/broad/software/dotkit/init -b`
#reuse -q .llvm-clang-3.7.1
#reuse -q .gcc-5.1.0

numsigs=476251
numthreads=8
buffersize=60000
numgenes=10174

while getopts ":hs:g:b:" opt; do
  case ${opt} in 
    h )
      echo "Usage ./run_working.sh [-options] upfile downfile outputfile genelist sigid score1 rank1 [score2 rank2]"
      echo "Optional args:"
      echo " -s (int) -  Number of signatures in score and rank matrices"
      echo " -g (int) - Number of genes per signature in score and rank matrices"
      echo " -b (int) - Size of buffer for storing signatures. Impacts memory usage"
      echo " -t (int) - Number of threads available for use in computation"
      exit 0
      ;;
    s )
      numsigs=$OPTARG
      ;;
    g )
      numgenes=$OPTARG
      ;;
    b )
      buffersize=$OPTARG
      ;;
    t )
      numthreads=$OPTARG
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid Option: -$OPTARG requires an argument" 1>&2
      exit 1
  esac
done
shift $((OPTIND -1))

upfile=$1
downfile=$2
outfile=$3
genelist=$4
sigids=$5
score=$6
rank=$7
score2=${8-$score}
rank2=${9-$rank}

dir=$(dirname "$0")
#echo $dir$

$dir/fastquery/fastquery --score $score --rank $rank --score2 $score2 --rank2 $rank2 --genelist $genelist --sigids $sigids --out $outfile --up $upfile --down $downfile --num-threads $numthreads --num-genes $numgenes --num-sigs $numsigs --buffer-size $buffersize


