#!/bin/bash
# Usage: interleave-reads.sh R1 R2 NAME_FOR_INTERLEAVED_READS_FILE

# Used to join two fastq read files into an interleaved fastq read
# file (forward and reverse reads come after another in the same file)
# Modified after Nathan S. Watson-Haigh (https://gist.github.com/4544979) 

R1=$1
R2=$2
output=$3

paste $R1 $R2 | paste - - - - | awk -v OFS="\n" -v FS="\t" '{print($1,$3,$5,$7,$2,$4,$6,$8)}' > interleaved.fastq
cat tmp.fastq | cut -f1 -d" " | sed '1~8 s/$/\/1/g' | sed '5~8 s/$/\/2/g' > $output
rm tmp.fastq
