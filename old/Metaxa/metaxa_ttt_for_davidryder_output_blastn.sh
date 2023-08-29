#!/bin/bash

#prepare data for metaxa_ttt
awk -F'\t+' -v OFS='\t' '{$(NF+1)=$15; $15=""; $0=$0; $1=$1}1' alignments_with_lineages.blastn > data_rearranged.txt
cut -f15- data_rearranged.txt | sed 's/\t/;/g' > classification.txt
cut -f3,4 alignments_with_lineages.blastn > info.txt
cat alignments_with_lineages.blastn | cut -f1 | paste -d'\t' - classification.txt | paste -d'\t' - info.txt > data_prepared_for_metaxa_ttt.txt

#run metaxa_ttt
metaxa2_ttt -i data_prepared_for_metaxa_ttt.txt -o metaxa_ttt

#sort files
mkdir metaxa_ttt/
mv metaxa_ttt.level* metaxa_ttt.tax* metaxa_ttt/
mkdir data_preparation_for_metaxa_ttt_outputs
mv data_prepared_for_metaxa_ttt.txt info.txt classification.txt data_rearranged.txt data_preparation_for_metaxa_ttt_outputs/