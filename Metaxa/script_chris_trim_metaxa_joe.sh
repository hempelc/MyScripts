#!/bin/bash
# script_chris_trim_metaxa_joe.sh <forward reads> <reverse reads> <prefix e.g. sample1>
# this script and the script tabtofasta.pl have to be in same folder as the input data

forward=$1
reverse=$2
prefix=$3

# Running TrimGalore
echo "Running TrimGalore..."
trim_galore --fastqc --dont_gzip --paired $1 $2

# Running Metaxa
echo "Running Metaxa..."
metaxa2 -1 ${forward::-9}_val_1.fq -2 ${reverse::-9}_val_2.fq

# Starting Joe's script
echo "Starting Joe's script"
prefix=$3

# Extract sequence IDs
echo "Extracting sequence IDs..."
less metaxa_out.extraction.fasta | grep \> | sed 's/|/\t/1' | cut -f1 | sed 's/>//1' > "list_"$prefix

# Extract fastq sequences
echo "Extracting fastq sequences..."
seqtk subseq $1 "list_"$prefix > "list_"$prefix"_R1.fastq"
seqtk subseq $2 "list_"$prefix > "list_"$prefix"_R2.fastq"

# Identify overlapping reads
echo "Running flash to identify overlapping reads..."
flash "list_"$prefix"_R1.fastq" "list_"$prefix"_R2.fastq" -M 250 -m 10

# Convert fastq to fasta
echo "Converting fastq to fasta..."
for i in out*.fastq
do echo $i
seqtk seq -a $i > $prefix"_"$i".fasta"
done

# Add sample prefixs to fasta files
echo "Adding sample prefixs to sequence IDs..."
for j in $prefix"_"*.fastq.fasta
do
less $j | paste - - | sed 's/>/'$prefix'_/1' | sed 's/ /___/1' | ./tabtofasta.pl - | sed 's/___/ /1' > $j"2"
rm $j
done

# Merge corresponding forward and reverse reads

# Format fasta files
for i in $prefix"_"*.fastq.fasta2
do fasta_formatter -i $i -o $i"3"
done

# Reverse compliment of reverse reads
reverse_reads=`ls $prefix"_"*2.fastq.fasta23`
echo $reverse_reads
seqtk seq -r $reverse_reads > reverse_reads.fasta


# Merge forward and "RC-ed" reverse reads for each pair
less $prefix"_"*1.fastq.fasta23  | sed 's/ /\t/1' | cut -f1 | sed 's/>//1' | paste - - > temp1
less reverse_reads.fasta | sed 's/ /\t/1' | cut -f1 | sed 's/>//1' | paste - - | cut -f2 > temp2
paste temp1 temp2 | sed 's/\t//2' > temp3
./tabtofasta.pl temp3 > temp3.fasta

# Concatenate overlapped reads file with  merged forward and reverse reads file to make file ready for extraction
cat $prefix"_out.extendedFrags.fastq.fasta2" temp3.fasta>catted_reads.fasta

# Move all unneeded generated files to a new directory called output
mkdir joes_script_output
mv temp* list* out* *fasta2 *fasta23 reverse* catted_reads.fasta joes_script_output/

mkdir trimgalore_output
mv *_val_* *trimming_report.txt trimgalore_output/

mkdir metaxa_output
mv metaxa_out.* metaxa_output/