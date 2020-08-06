#!/bin/bash

#SBATCH --time=24:00:00
#SBATCH --mem=115G
#SBATCH --cpus-per-task=16

# A script to assemble mitogenomes on the compute canada graham cluster

# Usage: when submitting with sbatch, you must define the variables $R1,
# $R2, and $length. R1=forward reads, R2=reverse reads, length=read length.
# Therefore, use the sbatch parameter --export=variable_name='file' and separate
# variables by commas without spaces.
# Example: sbatch ... --export=R1='forward_reads.fq',R2='reverse_reads.fq',length='100'

usage="$(basename "$0" "$1") --export=R1='<forward_reads.fq>',\
R2='<reverse_reads.fq>',length='<read length>'"

# Check if required options are set
if [[  -z "$R1" || -z "$R2" || -z "$length" ]]
then
   echo -e "Variables R1, R2, and length must be set.\n"
   echo -e "$usage\n\n"
   echo -e "Exiting script.\n"
   exit
fi

# Print some job info
if [ X"$SLURM_STEP_ID" = "X" -a X"$SLURM_PROCID" = "X"0 ]
then
  echo "print =========================================="
	echo "print SLURM_JOB_ID = $SLURM_JOB_ID"
	echo "print SBATCH_TIMELIMIT = $SBATCH_TIMELIMIT"
  echo "print SLURM_MEM_PER_NODE = $SLURM_MEM_PER_NODE"
  echo "print SLURM_CPUS_PER_TASK = $SLURM_CPUS_PER_TASK"
  echo "print =========================================="
fi

# Set slurm options
memory=$SLURM_MEM_PER_NODE
threads=$SLURM_CPUS_PER_TASK

# Load modules on graham
module load singularity/3.5 openmpi/2.1.1 gcccore/.7.3.0 imkl/2018.3.222 \
nixpkgs/16.09 gcc/7.3.0 cuda/10.0.130 megahit/1.2.7 spades/3.13.1 \
idba-ud/1.1.3 trinity/2.9.0


# Running assemblers
megahit -t $threads -1 $R1 -2 $R2 -o ./MEGAHIT

spades.py -1 $R1 -2 $R2 -o SPADES

fq2fa --merge --filter $R1 $R2 idba_input.fa
idba_ud --num_threads $threads --pre_correction -r ./idba_input.fa -o IDBA_UD

Trinity --seqType fq --max_memory ${memory}G --left $R1 --right $R2 \
--CPU $threads --output TRINITY

/home/hempelc/programs/MitoZ/MitoZ.simg assemble --genetic_code 5 \
--clade Arthropoda \
--outprefix test \
--thread_number 8 \
--fastq1 $R1 \
--fastq2 $R2 \
--fastq_read_length $length \
--insert_size 250 \
--run_mode 2 \
--filter_taxa_method 1 \
--requiring_taxa 'Arthropoda'

## Run the MitoZ module findmitoscaf on all outputs
/home/hempelc/programs/MitoZ/MitoZ.simg findmitoscaf --genetic_code 5 \
--clade Arthropoda \
--outprefix test \
--thread_number $threads \
--fastq1 $R1 \
--fastq2 $R2 \
--fastq_read_length $length \
--fastafile ./SPADES/scaffolds.fasta


# Find mito contigs
## Make list of files from assemblers (all but mitoZ)
#assembly_list=(./SPADES/scaffolds.fasta ./MEGAHIT/contigs.fa \
#./IDBA_UD/contig.fa ./TRINITY/Trinity.fa)

### Run the MitoZ module findmitoscaf on all outputs
#for i in $assembly_list; do
#/home/hempelc/programs/MitoZ/MitoZ.simg findmitoscaf --genetic_code 5 \
#--clade Arthropoda \
#--outprefix test \
#--thread_number $threads \
#--fastq1 $R1 \
#--fastq2 $R2 \
#--fastq_read_length $read_length \
#--fastafile $i


# Annotate seqs

#/home/hempelc/programs/MitoZ/MitoZ.simg --genetic_code 5 --clade Arthropoda \
#--outprefix test --thread_number 8 \
#--fastafile mitogenome.fa


# Visualize seqs

#/home/hempelc/programs/MitoZ/MitoZ.simg visualize --gb mitogenome.gb
