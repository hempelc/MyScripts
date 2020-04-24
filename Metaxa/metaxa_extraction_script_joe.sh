#!/bin/bash
# metaxa_script.sh <metaxa file> <forward reads> <reverse reads>
#

sample_name=$1
forward=$2
reverse=$3
name=`echo $sample_name | sed 's/out/\t/1' | cut -f1`
echo $name

# Extract sequence IDs
echo "Extracting sequence IDs..."
less $1 | grep \> | sed 's/|/\t/1' | cut -f1 | sed 's/>//1' > "list_"$name

# Extract fastq sequences
echo "Extracting fastq sequences..."
seqtk subseq $2 "list_"$name > "list_"$name"_R1.fastq"
seqtk subseq $3 "list_"$name > "list_"$name"_R2.fastq"

# Identify overlapping reads
echo "Running flash to identify overlapping reads..."
flash "list_"$name"_R1.fastq" "list_"$name"_R2.fastq" -M 250 -m 10

# Convert fastq to fasta
echo "Converting fastq to fasta..."
for i in out*.fastq
do echo $i
seqtk seq -a $i > $name"_"$i".fasta"
done

# Add sample names to fasta files
echo "Adding sample names to sequence IDs..."
for j in $name"_"*.fastq.fasta
do
less $j | paste - - | sed 's/>/'$name'_/1' | sed 's/ /___/1' | ./tabtofasta.pl - | sed 's/___/ /1' > $j"2"
rm $j
done

# Merge corresponding forward and reverse reads

# Format fasta files
for i in $name"_"*.fastq.fasta2
do fasta_formatter -i $i -o $i"3"
done

# Reverse compliment of reverse reads
reverse_reads=`ls $name"_"*2.fastq.fasta23`
echo $reverse_reads
seqtk seq -r $reverse_reads > reverse_reads.fasta


# Merge forward and "RC-ed" reverse reads for each pair
less $name"_"*1.fastq.fasta23  | sed 's/ /\t/1' | cut -f1 | sed 's/>//1' | paste - - > temp1
less reverse_reads.fasta | sed 's/ /\t/1' | cut -f1 | sed 's/>//1' | paste - - | cut -f2 > temp2
paste temp1 temp2 | sed 's/\t//2' > temp3
./tabtofasta.pl temp3 > temp3.fasta

# Concatenate overlapped reads file with  merged forward and reverse reads file to make file ready for extraction
cat $name"_out.extendedFrags.fastq.fasta2" temp3.fasta>catted_reads.fasta

# Move all unneeded generated files to a new directory called output
mkdir joes_script_output
mv temp* list* out* *fasta2 *fasta23 reverse* ./joes_script_output
