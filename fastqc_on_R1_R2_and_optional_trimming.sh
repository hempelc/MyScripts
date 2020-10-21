#!/bin/bash

# Version 0.2, made on 27 Aug 2020 by Chris Hempel (hempelc@uoguelph.ca)

# Takes R1 and R2 reads, performs FastQC on the raw reads, then, if specified,
<<<<<<< HEAD
# trims them using Trimmomatic with a list of PHRED scores and performs FastQC
=======
# trims them using Trimmomatic # with a list of PHRED scores and performs FastQC
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd
# on all trimmed read sets

# FastQC must be installed and in path

<<<<<<< HEAD
# A folder with adapters to trim must be located in the same folder as the
# trimmomatic .jar application and called "adapters" (that's usually the case
# when you install trimmomatic).
# For now, the used adapter sequences are fixed, and can be changed in line 122

# For some reason, the limit of the PHRED score can only be set to 38, FastQC is
# not able to deal with data generated with higher PHRED scores (in my test).
=======
# A folder with adapters to trim must be located in the same folder as the trimmomatic .jar application
# and called "adapters" (that's usually the case when you install trimmomatic)
# For now, the used adapter sequences are fixed, and can be changed in line 122

# For some reason, the limit of the PHRED score can only be set to 38, FastQC is not able to deal with data
# generated with higher PHRED scores (in my test)
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd

usage="$(basename "$0") -1 <R1.fastq> -2 <R2.fastq> -t <yes|no> [-T <path/to/trimmomatic.jar> -P <'score score score ...'> -l <length> -p <threads>]

Usage:
	-1  Reads1 (can also be .gz compressed)
	-2  Reads2 (can also be .gz compressed)
	-t	yes: trim reads (needs -T specified); no: don't trim reads
	-T  Path to trimmomatic java application (.jar)
	-P  PHRED scores to trim on (default: '5 10 15 20' (numbers must be surrounded by ' ' and separated only by space); based on recommendations of MacMarnes 2014 and a literature review of papers that cite them)
	-l  Minimum read length to keep (default: 25 , based on recommendations of MacMarnes 2014 and a literature review of papers that cite them)
	-p  Number of threads used	(default: 16)
	-h  Display this help and exit"

<<<<<<< HEAD
# Set default options:
=======
# Set default options
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd
PHRED='5 10 15 20'
min_length='25'
threads='16'


<<<<<<< HEAD
# Set specified options:
=======
# Set specified options
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd
while getopts ':1:2:t:T:P:l:p:h' opt; do
  case "${opt}" in
  	1) R1="${OPTARG}" ;;
	  2) R2="${OPTARG}" ;;
		t) trimming="${OPTARG}" ;;
		T) trimmomatic="${OPTARG}" ;;
		P) PHRED="${OPTARG}" ;;
		l) min_length="${OPTARG}" ;;
		p) threads="${OPTARG}" ;;
		h) echo "$usage"
		   exit ;;
		:) printf "Option -$OPTARG requires an argument."
		   echo -e "\n$usage"
		   exit ;;
	   \?) printf "Invalid option: -$OPTARG"
		   echo -e "\n$usage"
		   exit
  esac
done
shift $((OPTIND - 1))


<<<<<<< HEAD
# Check if required options are set:
=======
# Check if required options are set
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd
if [[ -z "$R1" || -z "$R2" || -z "$trimming" ]]
then
   echo -e "-1, -2, and -t must be set.\n"
   echo -e "$usage\n\n"
   echo -e "Exiting script.\n"
   exit
fi

if [[ $trimming != 'yes' && $trimming != 'no' ]]
then
  echo -e "Invalid option for -t, must be set to either 'yes' or 'no'\n"
  echo -e "$usage\n\n"
  echo -e "Exiting script\n"
  exit
fi

if [[ $trimming == 'yes' && $trimmomatic == '' ]]
then
  echo -e "Option -T must be set when using -t yes.'\n"
  echo -e "$usage\n\n"
  echo -e "Exiting script\n"
  exit
fi


######################## Write time, options etc. to output #########################

# Making output directory for this script and open bracket to later tell script to write logfile
mkdir trimming_with_phred_scores_and_fastqc_report_output/
(


<<<<<<< HEAD
# Define starting time of script for total runtime calculation:
=======
# Define starting time of script for total runtime calculation
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd
start=$(date +%s)
echo -e "\nSTART RUNNING SCRIPT AT $(date)\n"


<<<<<<< HEAD
# Output specified options:
=======
# Output specified options
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd
echo -e "~~~~~~~~~~ OPTIONS ~~~~~~~~~~\n"

echo -e "R1 was defined as $R1."
echo -e "R2 was defined as $R2."
if [[ $trimming == "no" ]] ; then
	echo -e "Trimming was turned off."
else
	echo -e "Trimming was turned on."
	echo -e "Trimmomatic is located in $trimmomatic."
	echo -e "PHRED scores to trim on are $PHRED."
	echo -e "Minimum length of reads is $min_length."
fi
echo -e "Number of threads was set to $threads."

<<<<<<< HEAD
##### Start of script #####
=======
##### Start of script
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd

baseout=$(echo ${R1%_*}) # Make basename

if [[ $trimming == "yes" ]] ; then
	# Running Trimmomatic
	echo -e "\n\n~~~~~~~~~~ RUNNING TRIMMOMATIC ~~~~~~~~~~\n"
	mkdir trimming_with_phred_scores_and_fastqc_report_output/trimmomatic/
	for score in $PHRED; do
<<<<<<< HEAD
		# Run trimmomatic for every specified PHRED score and save output in separate directory
		mkdir trimming_with_phred_scores_and_fastqc_report_output/trimmomatic/trimmed_at_phred_$(echo $score)_$(echo ${baseout##*/})
		java -jar $trimmomatic PE $R1 $R2 ILLUMINACLIP:$(echo ${trimmomatic%/*})/adapters/TruSeq3-PE.fa:2:30:10 LEADING:$score TRAILING:$score SLIDINGWINDOW:4:$score MINLEN:$min_length \
		-baseout trimmed_at_phred_$(echo $score)_$(echo ${baseout##*/}).fastq \
		-threads $threads
		echo -e '\n'
		mv trimmed_at_phred_$(echo $score)_$(echo ${baseout##*/})*.fastq \
		trimming_with_phred_scores_and_fastqc_report_output/trimmomatic/trimmed_at_phred_$(echo $score)_$(echo ${baseout##*/})
=======
		mkdir trimming_with_phred_scores_and_fastqc_report_output/trimmomatic/trimmed_at_phred_$(echo $score)_$(echo ${baseout##*/})
		java -jar $trimmomatic PE $R1 $R2 ILLUMINACLIP:$(echo ${trimmomatic%/*})/adapters/TruSeq3-PE.fa:2:30:10 LEADING:$score TRAILING:$score SLIDINGWINDOW:4:$score MINLEN:$min_length -baseout trimmed_at_phred_$(echo $score)_$(echo ${baseout##*/}).fastq -threads $threads
		echo -e '\n'
		mv trimmed_at_phred_$(echo $score)_$(echo ${baseout##*/})*.fastq trimming_with_phred_scores_and_fastqc_report_output/trimmomatic/trimmed_at_phred_$(echo $score)_$(echo ${baseout##*/})
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd
	done
fi

# Running FastQC
echo -e "\n\n~~~~~~~~~~ RUNNING FASTQC ~~~~~~~~~~\n"
mkdir trimming_with_phred_scores_and_fastqc_report_output/fastqc_reports
mkdir trimming_with_phred_scores_and_fastqc_report_output/fastqc_reports/untrimmed_${baseout##*/}
fastqc $R1 -o trimming_with_phred_scores_and_fastqc_report_output/fastqc_reports/untrimmed_${baseout##*/}
echo -e "\n"
fastqc $R2 -o trimming_with_phred_scores_and_fastqc_report_output/fastqc_reports/untrimmed_${baseout##*/}
echo -e "\n"

<<<<<<< HEAD
#  Run FastQC on trimmed data if trimming was activated:
=======
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd
if [[ $trimming == "yes" ]] ; then
	for reads in trimming_with_phred_scores_and_fastqc_report_output/trimmomatic/trimmed_at_phred_*$(echo ${baseout##*/})/*_1P.fastq; do
		dir_name=${reads%_*} # making variable so that read names can be used to make directory
		mkdir trimming_with_phred_scores_and_fastqc_report_output/fastqc_reports/$(echo ${dir_name##*/})
		fastqc $reads -o trimming_with_phred_scores_and_fastqc_report_output/fastqc_reports/$(echo ${dir_name##*/}) -t $threads
		echo -e "\n"
	done

	for reads in trimming_with_phred_scores_and_fastqc_report_output/trimmomatic/trimmed_at_phred_*$(echo ${baseout##*/})/*_2P.fastq; do
		dir_name=${reads%_*} # making variable so that read names can be used to sort into directory
		fastqc $reads -o trimming_with_phred_scores_and_fastqc_report_output/fastqc_reports/$(echo ${dir_name##*/}) -t $threads
		echo -e "\n"
	done
fi

# Display runtime
<<<<<<< HEAD
echo -e "=================================================================\n"
echo "SCRIPT DONE AFTER $((($(date +%s)-$start)/3600))h $(((($(date +%s)-$start)%3600)/60))m"
=======
echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nSCRIPT RUNTIME: $((($(date +%s)-$start)/3600))h $(((($(date +%s)-$start)%3600)/60))m"
>>>>>>> 4666263b4586385e646d44985c8e0d82c90d47cd


# Write output to console and log file
) 2>&1 | tee trimming_with_phred_scores_and_fastqc_report_output/trimming_with_phred_scores_and_fastqc_report_log.txt
