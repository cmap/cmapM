#!/bin/bash -l
# Example:
# montage -label '%f' -trim BRD-K16323731.png BRD-K16329066.png BRD-K16331350.png  -geometry 400x400+1+1 -tile 2x2 output.png

aux_files=$1
path_to_figures=$2
clust_id_fname=$3
clust_iname_fname=$4
outpath=$5

for n in `awk '{print $1}' $clust_id_fname`
do
    echo "Printing figures with 2D structures of compounds in cluster: $n"
    lpert_id=`grep ^$n $clust_id_fname | awk '{for(i=3;i<=NF;i++) print $i}'`

    count=0
    for id in $lpert_id
    do
        pert_iname=`grep $id $aux_files/smiles_cmap.txt | awk '{print $2}'`
        lpert_iname[$count]=$pert_iname
        let "count+=1"
    done

    average_tani=`grep ^$n $clust_iname_fname | awk 'BEGIN{FS="\t"}{print $2}'| awk 'BEGIN{FS=","}{print $2}'`
    average_summly=`grep ^$n $clust_iname_fname | awk 'BEGIN{FS="\t"}{print $2}'| awk 'BEGIN{FS=","}{print $4}'`
    
    lfigures=`echo $lpert_id | \
        awk -v lpi="${lpert_iname[*]}" -v pf=$path_to_figures 'BEGIN{split(lpi,llpi)}{for(i=1;i<=NF;i++) print "-label "llpi[i]" "pf"/"$i".png"} \
            END{if (NF%3==0) print "-tile 3x"int(NF/3); else print "-tile 3x"int(NF/3+1)}'`
    montage -label '%t' -trim -pointsize 26 -title "Cluster ID: $n, <Tanimoto>: $average_tani, <PS>: $average_summly" \
        $lfigures -geometry 400x200+30+10 $outpath/${n}_structures.png
done
