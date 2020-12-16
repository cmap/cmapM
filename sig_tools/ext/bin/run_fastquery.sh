#!/bin/bash

#export LD_LIBRARY_PATH=/broad/software/free/Linux/redhat_6_x86_64/pkgs/gcc_5.1.0/lib64/libstdc++.so.6:$LD_LIBRARY_PATH
#echo $LD_LIBRARY_PATH

eval `/broad/software/dotkit/init -b`
#reuse -q .llvm-clang-3.7.1
reuse -q .gcc-5.1.0

NUMTHREADS=8

while test $# -gt 0; do
  case "$1" in
    -h|--help)
        printf "Usage fast_gutc.sh [options]\nOptions include:\n"
        printf -- "-s, --score \t Path to binary score matrix\n"
        printf -- "-r, --rank \t Path to binary rank matrix\n"
        printf -- "-g, --genelist \t Path to GRP file containing list of genes in BING spcae\n"
        printf -- "-i, --sigids \t PATH to GRP file containing IDs for signatures in score matrix\n"
        printf -- "-s2, --score2 \t Path to copy of binary score matrix, ideally stored on separate SSD for parallel loading.\n \t \t If not available, path to singular score matrix can be supplied to both\n"
        printf -- "-r2, --rank2 \t Path to copy of binary rank matrix for parallel loading\n"
        printf -- "-u, --uptag \t Path to GRP or GMT containing list(s) of query genes with expected up-regulation\n"
        printf -- "-d, --dntag \t Path to GRP or GMT containing lists(s) of query genes with expected down-regulation\n"
        printf -- "-f, --outfile \t Query results filename. Ends with .gct \n"
        printf -- "-n, --num_threads \t Number of threads available for use in query \n"
        printf -- "-t, --es_tail \t Specify two-tailed or one-tailed statistic for enrichment metric {both|up}\n"
        printf -- "-h, --help \t Print this help text\n"
        exit 0
        ;;
    -s|--score)
        shift
        SCORE=$1
        shift
        ;;
    -r|--rank)
        shift
        RANK=$1
        shift
        ;;
    -g|--genelist)
        shift
        GENELIST=$1
        shift
        ;;
    -i|--sigids)
        shift
        SIGIDS=$1
        shift
        ;;
    -s2|--score2)
        shift
        SCORE2=$1
        shift
        ;;
    -r2|--rank2)
        shift
        RANK2=$1
        shift
        ;;
    -u|--uptag)
        shift
        UPTAG=$1
        shift
        ;;
    -d|--dntag)
        shift
        DNTAG=$1
        shift
        ;;
    -f|--outfile)
        shift
        OUTFILE=$1
        shift
        ;;
    -n|--num_threads)
        shift
        NUMTHREADS=$1
        shift
        ;;
    -t|--es_tail)
        shift
        ES_TAIL=$1
        shift
        ;;
    *)
        printf "Unknown parameter: %s \n" "$1"
        exit 1
        ;;
  esac
done

dir=$(dirname "$0")
#echo $dir$

case "$ES_TAIL" in 
  both)
    echo $dir/fastquery/fastquery --score $SCORE --rank $RANK --score2 $SCORE2 --rank2 $RANK2 --genelist $GENELIST --sigids $SIGIDS --out $OUTFILE --es_tail 'both' --up $UPTAG --down $DNTAG --num-threads $NUMTHREADS
    $dir/fastquery/fastquery --score $SCORE --rank $RANK --score2 $SCORE2 --rank2 $RANK2 --genelist $GENELIST --sigids $SIGIDS --out $OUTFILE --es_tail 'both' --up $UPTAG --down $DNTAG --num-threads $NUMTHREADS
    ;;
  up)
    echo $dir/fastquery/fastquery --score $SCORE --rank $RANK --score2 $SCORE2 --rank2 $RANK2 --genelist $GENELIST --sigids $SIGIDS --out $OUTFILE --es_tail 'up' --up $UPTAG --num-threads $NUMTHREADS
    $dir/fastquery/fastquery --score $SCORE --rank $RANK --score2 $SCORE2 --rank2 $RANK2 --genelist $GENELIST --sigids $SIGIDS --out $OUTFILE --es_tail 'up' --up $UPTAG --num-threads $NUMTHREADS
    ;;
  down)
    echo $dir/fastquery/fastquery --score $SCORE --rank $RANK --score2 $SCORE2 --rank2 $RANK2 --genelist $GENELIST --sigids $SIGIDS --out $OUTFILE --es_tail 'down' --down $DNTAG --num-threads $NUMTHREADS
    $dir/fastquery/fastquery --score $SCORE --rank $RANK --score2 $SCORE2 --rank2 $RANK2 --genelist $GENELIST --sigids $SIGIDS --out $OUTFILE --es_tail 'down' --down $DNTAG --num-threads $NUMTHREADS
  ;;
	*)
    printf "Unknown parameter: %s \n", "$1"
    exit 1
    shift 2
    ;;
esac


