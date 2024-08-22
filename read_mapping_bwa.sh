#!/bin/bash
#usage: bwa_script.sh reference.fasta R1_trimmed.fq R2_trimmed.fq <-- file formats important
#script expects trimmed reads in .fq format so far
#results in file "bwa_ala_sorted_$reference_name.bam" than can be opened in e.g. Genious
reference=$1
R1=$2
R2=$3

name1=$(echo ${R1##*/})
name2=$(echo ${R2##*/})
reference_name_tmp=$(echo ${reference##*/})
reference_name=$(echo ${reference_name_tmp%%.*})

bwa index -a is $reference
bwa aln $reference $R1 > ${name1::-3}_bwa.sai
bwa aln $reference $R2 > ${name2::-3}_bwa.sai
bwa sampe -a 1500 $reference ${name1::-3}_bwa.sai ${name2::-3}_bwa.sai $R1 $R2 > bwa_ala_$reference_name.sam
samtools view -F 12 -Sbt $reference bwa_ala_$reference_name.sam > bwa_ala_$reference_name.bam
samtools sort bwa_ala_$reference_name.bam bwa_ala_sorted_$reference_name

rm $reference.* ${name1::-3}_bwa.sai ${name2::-3}_bwa.sai bwa_ala_$reference_name.sam bwa_ala_$reference_name.bam