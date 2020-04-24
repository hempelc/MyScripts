#!/bin/bash

# usage: ./bowtie2_map.sh index_reference read_file
# Create index - map reads 

index_reference=$1
read_file=$2

bowtie2-build -f $index_reference bowtie_index
bowtie2 -q -x bowtie_index --interleaved $read_file -S mapped_reads.sam

rm bowtie_index*