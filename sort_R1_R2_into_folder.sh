#!/usr/bin/env bash

#use when in folder containing pairs of reads
#script to sort all forward and reverse read files within a folder into separate folders
#for every pair, a folder with the SRA number is created
#pair is sorted into that folder, all files with same SRA number and containing _1 and _2 are sorted together
#start this script in the folder containing the forward and reverse reads

for file in ./*1.fastq*
do
	mkdir ${file%_*}
	mv $file ${file%_*}
done

for file in ./*2.fastq*
do
	mv $file ${file%_*}
done
