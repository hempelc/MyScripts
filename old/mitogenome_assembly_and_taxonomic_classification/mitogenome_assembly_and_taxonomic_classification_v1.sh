#!/bin/bash

usage="$(basename "$0") [-1 <R1.fastq.gz> -2 <R2.fastq.gz>] [-b <n>] [-k <n,n,n...>] [-p <FILE.fasta>] [-r <PREFIX>] [-tPcCsh] -- Script to assemble scaffolds out of a read set using SPAdes followed by prokka to annotate scaffolds, diamond to blast the annotated proteins, etxraction of all mitochondrial scaffolds and taxonomic classification of these.

Usage:
	-1   Reads1 (must be .fastq.gz, do not use when using -s)
	-2   Reads2 (must be .fastq.gz, do not use when using -s)
	-b   Number of blast hits (default: 5)
	-t   Trim reads before assembly using TrimGalore with default settings
	-P   Use plasmidSPAdes mode of SPAdes for assembly. If SPAdes was disabled, use flag to indicate the input originates from plasmidSPAdes
	-k   kmer size of SPAdes (default: 21,33,55,77; when changing use no whitespace between commas and only odd numbers)
	-c   Disable careful mode of SPAdes
	-C   Run prokka and following steps on contigs rather than scaffolds previously assembled by SPAdes
	-s   Disable SPAdes and only run prokka and following steps (needs -p and -r to be specified)
	-p   Input for prokka (only when using -s, needs to be either contigs or scaffolds output of different (plasmid)SPAdes run, if input originates from plasmidSPAdes, additonally use -P flag)
	-r   Prefix for prokka (only when using -s)
	-h   Display this help and exit"

prokka_input=''
blast_k='5'
kmer_spades='21,33,55,77'
trim='false'
spades='true'
plasmid='false'
careful='true'
prokka_prefix=''
scaffolds='true'

while getopts ':p:1:2:b:tsPk:cCr:h' opt; do
  case "${opt}" in
  	p) prokka_input="${OPTARG}" ;;
    1) R1="${OPTARG}" ;;
    2) R2="${OPTARG}" ;;
	b) blast_k="${OPTARG}" ;;
	t) trim='true' ;;
	s) spades='false' ;;
	P) plasmid='true' ;;
	k) kmer_spades="${OPTARG}" ;;
	c) careful='false' ;;
	C) scaffolds='false' ;;
	r) prokka_prefix="${OPTARG}" ;;
	h) echo "$usage"
	   exit ;;
	:) printf "Option -$OPTARG requires an argument." >&2 ;;
   \?) printf "Invalid option: -$OPTARG" >&2 ;;
  esac
done
shift $((OPTIND - 1))

##############################################

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>mitogenome_assembly_and_taxonomic_classification_log.txt 2>&1

start=$(date +%s)

echo -e "\nSTART RUNNING SCRIPT AT $(date)\n"

echo -e "~~~~~~~~~~ OPTIONS ~~~~~~~~~~\n\n"

if [[ $spades == 'false' && $prokka_input == '' ]]
	then
		echo -e "SPAdes was disabled with -s flag but no input file for prokka was defined. Use -p <FILE>.\n" >&2
		echo -e "$usage\n" >&2
		echo -e "Exiting script.\n" >&2
		exit 1
fi

if [[ $spades == 'false' && $prokka_prefix == '' ]]
	then
		echo -e "When disabling SPAdes, you have to define a prefix for prokka. Use -r <PREFIX>.\n" >&2
		echo -e "$usage\n" >&2
		echo -e "Exiting script.\n" >&2
		exit 1
fi

if [[ $spades == 'true' && $prokka_input != '' ]]
	then
		echo -e "You are not allowed to change the input for prokka (-p) when enabling SPAdes.\n" >&2
		echo -e "$usage\n" >&2
		echo -e "Exiting script.\n" >&2
		exit 1
fi		

if [[ $spades == 'true' ]]
	then
		if [[ $R1 == '' || $R2 == '' ]]
			then
				echo -e "When enabling SPAdes (no -s flag), -1 and -2 have to be specified.\n" >&2
				echo -e "$usage\n" >&2
				echo -e "Exiting script.\n" >&2
				exit 1
		else
			echo -e "R1 reads are specified as $R1."
			echo -e "R2 reads are specified as $R2."
		fi
fi

if [[ $spades == 'false' ]]
	then
		if [[ $careful == 'false' || $trim = 'true' || $kmer_spades != '21,33,55,77' ]]
			then
			echo -e "-s flag used: SPAdes has been disabled, therefore any of the used flags -k, -c, -p or -t do not have any effect."
		else
			echo -e "-s flag used: SPAdes has been disabled."
		fi
else
	echo -e "Using SPAdes for assembly."
fi


if [[ $spades == 'true' ]]
	then
		if [[ $trim == 'true' ]]
			then
				echo -e "-t flag enabled: reads are supposed to be untrimmed and will be trimmed using TrimGalore with default options."
		else
			echo -e "-t flag not used: reads are supposed to be already trimmed."
		fi
fi

if [[ $spades == 'true' && $kmer_spades != '21,33,55,77' ]]
	then
		echo -e "kmer size of SPAdes was manually set to $kmer_spades."
fi


if [[ $spades == 'true' && $plasmid == 'true' ]]
	then
		echo -e "Mode for SPAdes was set to plasmidSPAdes."
fi


if [[ $spades == 'true' && $careful == "false" ]]
	then
		echo -e "Parameter --careful of SPAdes was disabled."
fi

if [[ $spades == 'true' ]]
	then
		if [[ $scaffolds == 'true' ]]
			then
				echo -e "prokka will run on scaffolds assembled by SPAdes."
		else 
			echo -e "prokka will run on contigs assembled by SPAdes."
		fi
else
	echo -e "prokka will run on file $prokka_input."
fi

if [[ $spades == 'false' && $plasmid == 'true' ]]
	then
		echo -e "File $prokka_input is supposed to originate from plasmidSPAdes."
else
	echo -e "File $prokka_input is supposed to originate from SPAdes."

fi


echo -e "Number of blast hits was set to $blast_k."

name1=$(echo ${R1##*/})
name2=$(echo ${R2##*/})


#################################################


if [[ $trim == 'true' ]]
	then
	# Running TrimGalore
	echo -e "\n\n~~~~~~~~~~ RUNNING TRIMGALORE ~~~~~~~~~~\n\n"
	mkdir trimgalore_output
	trim_galore --fastqc --paired --gzip -o trimgalore_output $R1 $R2
	echo -e "\n"
fi


if [[ $spades == 'true' ]]
	then
	# Running SPAdes
	echo -e "\n\n~~~~~~~~~~ RUNNING SPADES ~~~~~~~~~~\n\n"
	mkdir spades_output
	if [[ $trim == 'true' ]]
		then
			spades_reads1=$(echo ./trimgalore_output/${name1::-9}_val_1.fq.gz)
			spades_reads2=$(echo ./trimgalore_output/${name2::-9}_val_2.fq.gz)
	else
		spades_reads1=$R1
		spades_reads2=$R2
	fi

	if [[ $plasmid == 'true' ]]
		then
			if [[ $careful == 'true' ]]
				then
					spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades --plasmid --careful 
			else
				spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades --plasmid
			fi 
	elif [[ $careful == 'true' ]]
		then
			spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades --careful 
	else
		spades.py -1 $spades_reads1 -2 $spades_reads2 -o spades_output -k $kmer_spades
	fi


	# Shorten scaffolds/contigs names for prokka
	if [[ $scaffolds == 'true' ]]
		then
			sed -re 's/(>NODE_[0-9]+)[^=]*$/\1/' ./spades_output/contigs.fasta > ./spades_output/scaffolds_shorter_names_for_prokka.fasta
	else
		sed -re 's/(>NODE_[0-9]+)[^=]*$/\1/' ./spades_output/scaffolds.fasta > ./spades_output/scaffolds_shorter_names_for_prokka.fasta
	fi	
fi

# Running prokka
echo -e "\n\n~~~~~~~~~~ RUNNING PROKKA ~~~~~~~~~~\n\n"

if [[ $spades == 'true' ]]
	then
		if [[ $scaffolds == 'true' ]]
			then
				prokka_input="./spades_output/scaffolds_shorter_names_for_prokka.fasta"
		else
			prokka_input="./spades_output/contigs_shorter_names_for_prokka.fasta"
		fi
fi

if [[ $spades == 'false' ]]
	then
		sed -re 's/(>NODE_[0-9]+)[^=]*$/\1/' $prokka_input > prokka_input_short_names.fasta
fi

if [[ $spades == 'true' ]]
	then
		prokka --notbl2asn --cpus 4 --outdir prokka_output --prefix prokka_$(echo ${name1%_*}) $prokka_input
else
	prokka --notbl2asn --cpus 4 --outdir prokka_output --prefix $prokka_prefix prokka_input_short_names.fasta
fi

# Blast prokka proteins translated from contigs (generated by spades) with diamond against diamond nr database in blast format plus taxonomic id plus scientific names
echo -e "\n\n~~~~~~~~~~ RUNNING DIAMOND ~~~~~~~~~~\n\n"

if [[ $spades == 'true' ]]
	then
		diamond blastp -d ~/Programs/Chris/DB/nr.dmnd -q ./prokka_output/prokka_$(echo ${name1%_*}).faa -o diamond_output.txt --salltitles -k $blast_k --outfmt 6  qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle staxids
else
	diamond blastp -d ~/Programs/Chris/DB/nr.dmnd -q ./prokka_output/$prokka_prefix.faa -o diamond_output.txt --salltitles -k $blast_k --outfmt 6  qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle staxids
fi

# Get nodenames and sequence ids from prokka output
if [[ $spades == 'true' ]]
	then
		cat ./prokka_output/prokka_$(echo ${name1%_*}).gff | grep -v '##' | sed 's/ID=//g' | sed 's/;/\t/1' | cut -f1,9 > node_seqid.txt
else
	cat ./prokka_output/$prokka_prefix.gff | grep -v '##' | sed 's/ID=//g' | sed 's/;/\t/1' | cut -f1,9 > node_seqid.txt
fi

# Merge nodenames and sequence ids on blast output
echo -e "\n\n~~~~~~~~~~ MERGING 1 ~~~~~~~~~~\n"
mergeFilesOnColumn.pl node_seqid.txt diamond_output.txt 2 1 | cut -f-1,3- > node_seqid_diamond_output.txt

# Only use mitochondrial hits
grep mitoch* node_seqid_diamond_output.txt > node_seqid_diamond_output_mitochondrial.txt

# Get scaffold/contig length and coverage
if [[ $spades == 'true' ]]
	then
		if [[ $scaffolds == 'true' ]]
			then
				sequences="./spades_output/scaffolds.fasta"
		else
			sequences="./spades_output/contigs.fasta"
		fi
else
	sequences=$prokka_input
fi

if [[ $plasmid == 'true' ]]
	then
		cat $sequences | grep '>' | cut -c 2- | sed 's/_/\t/2' | sed 's/_/\t/2' | sed 's/_/\t/2' | sed 's/_/\t/2' | cut -f1,3,5,6 > nodenames_length_coverage_component.txt
else
	cat $sequences | grep '>' | cut -c 2- | sed 's/_/\t/2' | sed 's/_/\t/2' | sed 's/_/\t/2' | sed 's/_/\t/2' | cut -f1,3,5 > nodenames_length_coverage.txt
fi

# Merge contig length and coverage on blast output
echo -e "\n\n~~~~~~~~~~ MERGING 2 ~~~~~~~~~~\n"

if [[ $plasmid == 'true' ]]
	then
		mergeFilesOnColumn.pl nodenames_length_coverage_component.txt node_seqid_diamond_output_mitochondrial.txt 1 1 | cut -f-4,6- > node_length_coverage_component_seqid_diamond_output_mitochondrial.txt
else
	mergeFilesOnColumn.pl nodenames_length_coverage.txt node_seqid_diamond_output_mitochondrial.txt 1 1 | cut -f-3,5- > node_length_coverage_seqid_diamond_output_mitochondrial.txt
fi


if [[ $plasmid == 'true' ]]
	then
		mitofile="node_length_coverage_component_seqid_diamond_output_mitochondrial.txt"
else
	mitofile="node_length_coverage_seqid_diamond_output_mitochondrial.txt"
fi


# Get taxonomic classification of blasthits

if [[ $plasmid == 'true' ]]
	then
		ete3 ncbiquery --info --search $(cut -f 18 $mitofile) >matching_lineages.tsv
else
	ete3 ncbiquery --info --search $(cut -f 17 $mitofile) >matching_lineages.tsv
fi

# Add taxonomic classification to blastoutput
echo -e "\n\n~~~~~~~~~~ ADDING TAXONOMIC CLASSIFICATION ~~~~~~~~~~\n\n"

if [[ $plasmid == 'true' ]]
	then
		LookupTaxonDetails2.py -b $mitofile -l matching_lineages.tsv -o final_output_mitochondrial_sequences_and_taxonomy.txt -t 18
else
	LookupTaxonDetails2.py -b $mitofile -l matching_lineages.tsv -o final_output_mitochondrial_sequences_and_taxonomy.txt -t 17
fi


echo -e "\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nSCRIPT RUNTIME: $((($(date +%s)-$start)/3600))h $((($(date +%s)-$start)%60))m"

# Delete warnings from first merging within log file <-- not sure where warnings come from, command however results in wanted output, warnings therefore ignored and deleted due to massive space in log file
sed -i '/^Use of/ d' mitogenome_assembly_and_taxonomic_classification_log.txt

# Sort files
mkdir final_output
mv node* matching_lineages.tsv nodenames_length_coverage.txt diamond_output.txt final_output_mitochondrial_sequences_and_taxonomy.txt final_output/

if [[ $spades == 'false' ]]
	then
		mv prokka_input_short_names.fasta final_output/
fi

if [[ $spades == 'true' ]]
	then
		mkdir mitogenome_assembly_and_taxonomic_classification_$(echo ${name1%_*})
else
	mkdir mitogenome_assembly_and_taxonomic_classification_$prokka_prefix
fi

if [[ $spades == 'true' ]]
	then
		if [[ $trim == 'true' ]]
			then
				mv prokka_output/ spades_output/ trimgalore_output/ final_output/ mitogenome_assembly_and_taxonomic_classification_log.txt mitogenome_assembly_and_taxonomic_classification_$(echo ${name1%_*})/
		else
				mv prokka_output/ spades_output/ final_output/ mitogenome_assembly_and_taxonomic_classification_log.txt mitogenome_assembly_and_taxonomic_classification_$(echo ${name1%_*})/
		fi
else
	mv prokka_output/ spades_output/ final_output/ mitogenome_assembly_and_taxonomic_classification_log.txt mitogenome_assembly_and_taxonomic_classification_$prokka_prefix/
fi
