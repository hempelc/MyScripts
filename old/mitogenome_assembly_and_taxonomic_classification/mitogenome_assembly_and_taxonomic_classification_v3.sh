#!/bin/bash

# Version v3, flag -d for diamond database added, script structure improved
# Needs ete3 conda env activated
# Needs prokka singularity file downlaoded and in PATH (prokka.sif)
# Note: --notbl2asn option must be manually added to prokka script, see https://github.com/tseemann/prokka/issues/246


usage="$(basename "$0") -d <diamond_nr_database_location> [-1 <R1.fastq.gz> -2 <R2.fastq.gz>] [-b <n>] [-k <n,n,n...>] [-i <FILE.fasta>] [-r <PREFIX>] [-tapcshT] -- Script to assemble scaffolds out of a read set using SPAdes followed by prokka to annotate scaffolds, diamond to blast the annotated proteins, extraction of all mitochondrial scaffolds and addition of taxonomic classification.

Usage:
    -d   Location of diamond nr database (always needed)
	-1   Reads1 (must be .fastq.gz, do not use when using -s)
	-2   Reads2 (must be .fastq.gz, do not use when using -s)
	-t   Trim reads before assembly using TrimGalore with default settings
	-a   Disable read error correction of SPAdes input (using --only-assembler option) and only run SPAdes assembler (note: it is recommended to run read error correction of SPAdes)
	-p   Use plasmidSPAdes mode of SPAdes for assembly (option --plasmid in spades). If SPAdes was disabled, use flag to indicate the input originates from plasmidSPAdes (plasmidSPADES output has a different format)
	-k   kmer size of SPAdes (default: SPAdes default based on read length; when changing, use no whitespace between commas and only odd numbers)
	-c   Disable --careful option of SPAdes
	-s   Disable SPAdes and only run prokka and following steps (needs -i and -r to be specified)
	-i   Input for prokka (only when using -s, needs to be scaffolds output of different (plasmid)SPAdes run or comparable program with same output format (or edit file format to the one of SPAdes output); if input originates from plasmidSPAdes, additonally use -p flag)
	-r   Prefix for prokka (only when using -s)
	-b   Number of blast hits for diamond (default: 5)
	-T   Number of threads used	(default: 16)
	-h   Display this help and exit"

# Set default options
prokka_input=''
blast_k='5'
kmer_spades=''
trim='false'
spades='true'
plasmid='false'
careful='true'
prokka_prefix=''
scaffolds='true'
error_correction='true'
dmnd_nr_db=''
threads='16'


# Set specified options
while getopts ':i:1:2:b:taspk:cCr:hd:T:' opt; do
  case "${opt}" in
  	i) prokka_input="${OPTARG}" ;;
    1) R1="${OPTARG}" ;;
    2) R2="${OPTARG}" ;;
	b) blast_k="${OPTARG}" ;;
	a) error_correction='false' ;;
	t) trim='true' ;;
	s) spades='false' ;;
	p) plasmid='true' ;;
	k) kmer_spades="${OPTARG}" ;;
	c) careful='false' ;;
	r) prokka_prefix="${OPTARG}" ;;
    d) dmnd_nr_db="${OPTARG}" ;;
	T) threads="${OPTARG}" ;;
	h) echo "$usage"
	   exit ;;
	:) printf "Option -$OPTARG requires an argument." >&2 ;;
   \?) printf "Invalid option: -$OPTARG" >&2 ;;
  esac
done
shift $((OPTIND - 1))

######################## Write time, options etc. to output #########################

# Tell script to write logfile
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>mitogenome_assembly_and_taxonomic_classification_log.txt 2>&1


# Define starting time of script for total runtime calculation
start=$(date +%s)
echo -e "\nSTART RUNNING SCRIPT AT $(date)\n"


# Output specified options and exit script if options are invalid
echo -e "~~~~~~~~~~ OPTIONS ~~~~~~~~~~\n\n"

if [[ $spades == 'false' && $prokka_input == '' ]]
	then
		echo -e "SPAdes was disabled with -s flag but no input file for prokka was defined. Use -p <FILE>.\n" >&2
		echo -e "$usage\n" >&2
		echo -e "Exiting script.\n" >&2
		exit 1
elif [[ $spades == 'false' && $prokka_prefix == '' ]]
	then
		echo -e "When disabling SPAdes, you have to define a prefix for prokka. Use -r <PREFIX>.\n" >&2
		echo -e "$usage\n" >&2
		echo -e "Exiting script.\n" >&2
		exit 1
elif [[ $spades == 'true' && $prokka_input != '' ]]
	then
		echo -e "You are not allowed to change the input for prokka (-p) when enabling SPAdes.\n" >&2
		echo -e "$usage\n" >&2
		echo -e "Exiting script.\n" >&2
		exit 1
elif [[ $spades == 'true' ]]
	then
		if [[ $R1 == '' || $R2 == '' ]]
			then
				echo -e "When enabling SPAdes (no -s flag), -1 and -2 have to be specified.\n" >&2
				echo -e "$usage\n" >&2
				echo -e "Exiting script.\n" >&2
				exit 1
		fi
fi

if [[ $dmnd_nr_db == '' ]]
	then
		echo -e "No diamond nr database was set. See -d.\n" >&2
		echo -e "$usage\n" >&2
		echo -e "Exiting script.\n" >&2
		exit 1
else
	echo -e "Diamond nr database is located in $dmnd_nr_db."
fi

if [[ $spades == 'true' ]]
	then
		echo -e "Using SPAdes for assembly."
		echo -e "R1 reads are specified as $R1."
		echo -e "R2 reads are specified as $R2."
		if [[ $trim == 'true' ]]
			then
				if [[ $error_correction == 'true' ]]
					then
						echo -e "-t flag enabled: reads are supposed to be untrimmed and will be trimmed using TrimGalore with default options."
				fi
		elif [[ $error_correction == 'true' ]]
			then
				echo -e "-t flag not used: reads are supposed to be already trimmed."
		fi

		if [[ $error_correction == 'false' ]]
			then
				if [[ $trim == 'false' ]]
					then
						echo -e "-a flag used: read error correction of SPAdes was disabled. Reads are supposed to be already error corrected by previous SPAdes run."
				else
					echo -e "-a flag used: read error correction of SPAdes was disabled. Reads are supposed to be already error corrected by previous SPAdes run. -t flag does not have any effect."
				fi
		fi

		if [[ $kmer_spades != '' ]]
			then
				echo -e "kmer size of SPAdes was manually set to $kmer_spades."
		else
			echo -e "kmer size for SPAdes will be determined by SPAdes based on read length."
		fi

		if [[ $plasmid == 'true' ]]
			then
				echo -e "-p flag used: mode for SPAdes was set to plasmidSPAdes."
		fi

		if [[ $careful == "false" ]]
			then
				echo -e "-c flag used: option --careful of SPAdes was disabled."
		fi
else
	echo -e "-s flag used: SPAdes has been disabled."
	echo -e "prokka will run on file $prokka_input."
	echo -e "Number of blast hits was set to $blast_k."
	if [[ $careful == 'false' || $trim == 'true' || $kmer_spades != '' || $error_correction == 'false' ]]
		then
			echo -e "WARNING: -s flag used: SPAdes has been disabled, therefore the flags -a, -k, -c or -t do not have any effect."
	fi
fi

######################### Beginning of actual pipeline ########################

# Activate the conda ete3 environment within this script to be able to run ete3.
# I found this solution # to activate conda environments in scripts here:
# https://github.com/conda/conda/issues/7980.
val "$(conda shell.bash hook)" # Without this, the conda environment cannot be
# activated within the script
conda activate ete3 # ete3 is our conda environemnt in which we installed ete3


# Define variables for SPAdes input and for generation of prefixes
name1=$(echo ${R1##*/})
name2=$(echo ${R2##*/})
if [[ $spades == 'true' ]]
	then
		name_prefix=$(echo ${name1%_*})
else
	name_prefix=$prokka_prefix
fi

if [[ $spades == 'true' ]]
	then
		if [[ $error_correction == 'true' && $trim == 'true' ]]
			then
				# Running TrimGalore
				echo -e "\n\n~~~~~~~~~~ RUNNING TRIMGALORE ~~~~~~~~~~\n\n"
				mkdir trimgalore_output
				trim_galore --fastqc --paired --gzip -o trimgalore_output $R1 $R2
				echo -e "\n"
		fi

		# Running SPAdes
		echo -e "\n\n~~~~~~~~~~ RUNNING SPADES ~~~~~~~~~~\n\n"
		mkdir spades_output
		if [[ $trim == 'true' ]]
			then
				spades_reads1=$(echo ./trimgalore_output/$name_prefix_val_1.fq.gz)
				spades_reads2=$(echo ./trimgalore_output/$name_prefix_val_2.fq.gz)
		else
			spades_reads1=$R1
			spades_reads2=$R2
		fi

		if [[ $kmer_spades != '' ]]
			then
				if [[ $plasmid == 'true' ]]
					then
						if [[ $careful == 'true' ]]
							then
								if [[ $error_correction == 'true' ]]
									then
										spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades -t $threads -m 50 --plasmid --careful
								else
									spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades -t $threads -m 50 --plasmid --careful --only-assembler
								fi
						elif [[ $error_correction == 'true' ]]
							then
								spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades -t $threads -m 50 --plasmid
						else
							spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades -t $threads -m 50 --plasmid --only-assembler
						fi
				elif [[ $careful == 'true' ]]
					then
						if [[ $error_correction == 'true' ]]
							then
								spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades -t $threads -m 50 --careful
						else
							spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades -t $threads -m 50 --careful --only-assembler
						fi
				elif [[ $error_correction == 'true' ]]
					then
						spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades -t $threads -m 50
				else
					spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades -t $threads -m 50 --only-assembler
				fi
		elif [[ $plasmid == 'true' ]]
			then
				if [[ $careful == 'true' ]]
					then
						if [[ $error_correction == 'true' ]]
							then
								spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -t $threads -m 50 --plasmid --careful
						else
							spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -t $threads -m 50 --plasmid --careful --only-assembler
						fi
				elif [[ $error_correction == 'true' ]]
					then
						spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -t $threads -m 50 --plasmid
				else
					spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -t $threads -m 50 --plasmid --only-assembler
				fi
		elif [[ $careful == 'true' ]]
			then
				if [[ $error_correction == 'true' ]]
					then
						spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -t $threads -m 50 --careful
				else
					spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -t $threads -m 50 --careful --only-assembler
				fi
		elif [[ $error_correction == 'true' ]]
			then
				spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -t $threads -m 50
		else
			spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -t $threads -m 50 --only-assembler
		fi


fi


# Shorten names of scaffolds due to character limitations for sequence names in prokka
if [[ $spades == 'true' ]]
	then
		sed -re 's/(>NODE_[0-9]+)[^=]*$/\1/' ./spades_output/contigs.fasta > ./spades_output/scaffolds_shorter_names_for_prokka.fasta
else
	sed -re 's/(>NODE_[0-9]+)[^=]*$/\1/' $prokka_input > prokka_input_shorter_names_for_prokka.fasta
fi


# Running prokka on scaffolds
echo -e "\n\n~~~~~~~~~~ RUNNING PROKKA ~~~~~~~~~~\n\n"

if [[ $spades == 'true' ]]
	then
		prokka_input="./spades_output/scaffolds_shorter_names_for_prokka.fasta"
		#prokka.sif prokka --notbl2asn --cpus $threads --outdir prokka_output --prefix prokka_$name_prefix $prokka_input
    		prokka.sif prokka --cpus $threads --outdir prokka_output --prefix prokka_$name_prefix $prokka_input
else
	#prokka.sif prokka --notbl2asn --cpus $threads --outdir prokka_output --prefix $prokka_prefix prokka_input_shorter_names_for_prokka.fasta
  prokka.sif prokka --cpus $threads --outdir prokka_output --prefix $prokka_prefix prokka_input_shorter_names_for_prokka.fasta
fi


# Blast proteins translated from scaffolds (by prokka) with diamond against the diamond nr database in blast format
echo -e "\n\n~~~~~~~~~~ RUNNING DIAMOND ~~~~~~~~~~\n\n"

if [[ $spades == 'true' ]]
	then
		diamond blastp -d $dmnd_nr_db -q ./prokka_output/prokka_$name_prefix.faa -o diamond_output.txt --salltitles -k $blast_k --outfmt 6  qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle staxids
else
	diamond blastp -d $dmnd_nr_db -q ./prokka_output/$prokka_prefix.faa -o diamond_output.txt --salltitles -k $blast_k --outfmt 6  qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle staxids
fi


# Get nodes and sequence ids from prokka output
if [[ $spades == 'true' ]]
	then
		cat ./prokka_output/prokka_$(echo ${name1%_*}).gff | grep -v '##' | sed 's/ID=//g' | sed 's/;/\t/1' | cut -f1,9 > node_seqid.txt
else
	cat ./prokka_output/$prokka_prefix.gff | grep -v '##' | sed 's/ID=//g' | sed 's/;/\t/1' | cut -f1,9 > node_seqid.txt
fi


# Merge nodes and sequence ids on blast output
echo -e "\n\n~~~~~~~~~~ MERGING 1 ~~~~~~~~~~\n"
mergeFilesOnColumn.pl node_seqid.txt diamond_output.txt 2 1 | cut -f-1,3- > node_seqid_diamond_output.txt


# Get mitochondrial hits and save in separate file
grep mitoch* node_seqid_diamond_output.txt > node_seqid_diamond_output_mitochondrial.txt


# Get scaffolds length and coverage
# TO DO: adapt so that not done for non-spades assemblers
if [[ $spades == 'true' ]]
	then
		sequences="./spades_output/scaffolds.fasta"
else
	sequences=$prokka_input
fi

if [[ $plasmid == 'true' ]]
	then
		cat $sequences | grep '>' | cut -c 2- | sed 's/_/\t/2' | sed 's/_/\t/2' | sed 's/_/\t/2' | sed 's/_/\t/2' | cut -f1,3,5,6 > node_length_coverage_component.txt
else
	cat $sequences | grep '>' | cut -c 2- | sed 's/_/\t/2' | sed 's/_/\t/2' | sed 's/_/\t/2' | sed 's/_/\t/2' | cut -f1,3,5 > node_length_coverage.txt
fi


# Merge contig length and coverage on blast output
echo -e "\n\n~~~~~~~~~~ MERGING 2 ~~~~~~~~~~\n"

if [[ $plasmid == 'true' ]]
	then
		mergeFilesOnColumn.pl node_length_coverage_component.txt node_seqid_diamond_output_mitochondrial.txt 1 1 | cut -f-4,6- > node_length_coverage_component_seqid_diamond_output_mitochondrial.txt
else
	mergeFilesOnColumn.pl node_length_coverage.txt node_seqid_diamond_output_mitochondrial.txt 1 1 | cut -f-3,5- > node_length_coverage_seqid_diamond_output_mitochondrial.txt
fi


# Get taxonomic classification of blasthits
if [[ $plasmid == 'true' ]]
	then
		mitofile="node_length_coverage_component_seqid_diamond_output_mitochondrial.txt"
		column=17
else
	mitofile="node_length_coverage_seqid_diamond_output_mitochondrial.txt"
	column=18
fi

ete3 ncbiquery --info --search $(cut -f $column $mitofile) >matching_lineages.tsv


# Add taxonomic classification to blastoutput
echo -e "\n\n~~~~~~~~~~ ADDING TAXONOMIC CLASSIFICATION ~~~~~~~~~~\n\n"

LookupTaxonDetails3.py -b $mitofile -l matching_lineages.tsv -o final_output_mitochondrial_sequences_and_taxonomy.txt -t $column


# Display runtime
echo -e "\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nSCRIPT RUNTIME: $((($(date +%s)-$start)/3600))h $((($(date +%s)-$start)%60))m"


# Delete warnings from first merging within log file <-- not sure where warnings come from, command however results in wanted output, warnings therefore ignored and deleted due to massive space in log file
sed -i '/^Use of/ d' mitogenome_assembly_and_taxonomic_classification_log.txt


# Sort files
mkdir final_output/
mv node* matching_lineages.tsv node_length_coverage.txt diamond_output.txt final_output_mitochondrial_sequences_and_taxonomy.txt final_output/

if [[ $spades == 'true' ]]
	then
		mkdir mitogenome_assembly_and_taxonomic_classification_$name_prefix/
		mv prokka_output/ spades_output/ final_output/ mitogenome_assembly_and_taxonomic_classification_log.txt mitogenome_assembly_and_taxonomic_classification_$name_prefix/
		if [[ $trim == 'true' ]]
			then
				mv trimgalore_output/ mitogenome_assembly_and_taxonomic_classification_$name_prefix/
		fi
else
	mv prokka_input_shorter_names_for_prokka.fasta final_output/
	mkdir mitogenome_assembly_and_taxonomic_classification_$prokka_prefix/
	mv prokka_output/ spades_output/ final_output/ mitogenome_assembly_and_taxonomic_classification_log.txt mitogenome_assembly_and_taxonomic_classification_$prokka_prefix/
fi
