#!/bin/bash

for folder in */; do
	name=$folder

	l1_aligned=$(wc -l $(echo $folder)sortmerna/out/aligned.fastq)
	l2_aligned=$(echo ${l1_aligned%% *})
	aligned=$(expr $l2_aligned / 4)

	l1_other=$(wc -l $(echo $folder)sortmerna/out/other.fastq)
	l2_other=$(echo ${l1_other%% *})
	other=$(expr $l2_other / 4)

	total=$(expr $aligned + $other)
	portion=$(printf %.2f\\n "$((100 *   $other/$total  ))e-2")

	echo -e "Dataset $(echo ${name%%/*}):\n"
	echo "Total reads: $total"
	echo "Aligned reads: $aligned"
	echo "Unaligned reads: $other"
	echo -e "Portion of non-rRNA reads: $portion%\n\n"
done

