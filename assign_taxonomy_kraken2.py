#!/bin/bash

# Run kraken2
kraken2 --db /hdd1/databases/kraken2_SILVA_DB/ --threads 16 scaffolds.fasta > test_kraken.txt

# extract the taxids column of the standard kraken output
cut -f3 test_kraken.txt > kraken_taxids.txt

# Access the SILVA taxonomy file and generate a file containing one column for each SILVA taxid and one column for the respective SILVA taxonomy path:
tail -n +2 /hdd1/databases/SILVA_database_mar_2020/taxonomy/files_to_make_NCBI_staxids/taxmap_slv_ssu_ref_nr_138.txt | cut -f 4,6 | sort -u > SILVA_paths_and_taxids.txt

# Kraken spits out the taxid 0 when no hit is found, but 0 doesn't exist in the SILVA taxonomy, so manually add taxid 0 with path “No hits” to the SILVA path file:
echo -e "No hits;\t0" > tmp && cat SILVA_paths_and_taxids.txt >> tmp && mv tmp SILVA_paths_and_taxids.txt

# Merge your kraken taxids with the SILVA path file to assign a SILVA taxonomy apth to every kraken hit
mergeFilesOnColumn.pl SILVA_paths_and_taxids.txt kraken_taxids.txt 2 1 > merge.txt
cut -f -2 merge.txt | sed 's/;\t/\t/g' > merge_edit.txt # Edit the output

# Extract the sequence names from the kraken output and generate a final file with sequence name, taxid, and SILVA path
cut -f 3 test_kraken.txt > names.txt
paste names.txt merge_cut_sed.txt | awk 'BEGIN {FS="\t"; OFS="\t"} {print $1, $3, $2}' > final.txt

# This file had now the same format as the output of CREST and can be translated into NCBI taxonomy the same way as CREST output
