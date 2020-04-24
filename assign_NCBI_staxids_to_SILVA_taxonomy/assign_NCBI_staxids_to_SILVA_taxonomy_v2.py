#!/usr/bin/python

# Version 2.0, made on 7rd Apr 2020 by Chris Hempel (hempelc@uoguelph.ca)

# Change to v 1.0: now uses NCBI staxids with only scientific names first, and then NCBI staxids with synonyms, misspellings, etc.
# That was needed because some scientific names of one species overlapped with synonym names of another species, which then overwrote the scientific name
# Now, synonym names are only used if no match to an scientifc name is found


# Usage: ./SILVA_taxonomy_to_NCBI_staxids_v2.py NCBI_staxids_scientific_file NCBI_staxids_non_scientific_file SILVA_taxonomy_file output_file_name

# Merges SILVA taxonomy paths with NCBI staxids

# SILVA taxonomy file needs to have two columns, first one with accession number and second one with taxonomy path
	# Get SILVA taxonomy file from https://www.arb-silva.de/fileadmin/silva_databases/current/Exports/taxonomy/taxmap_slv_ssu_ref_nr_138.txt.gz
	# Unzip and edit SILVA taxonomy file:
		# sed "s/ <[a-zA-Z -,.&:'0-9]*>//g" taxmap_slv_ssu_ref_nr_138.txt | tail -n +2 | sed -r 's/(.*)\t/\1/g' | cut -f 1,4 > taxmap_slv_ssu_ref_nr_138_edited_for_NCBI_staxid_script.txt
			# 1. removes <genus>, <family> etc. from taxonomic paths (otherwise the SILVA taxonomy won't match the NCBI taxonomy)
			# 2. removes header line (not needed)
			# 3. removes the last tab of each line so that taxonomy path is in one column
			# 4. removes alignment numbers

# NCBI staxids files needs to have two columns, first one with taxonomy name and second one with staxid
	# To get the NCBI staxids, download the ‘taxdmp.zip’ archive from ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdmp.zip, extract it and keep the ‘names.dmp’ file. This one contains staxids for all scientific names, as well as non-scientific synonyms etc.
	# Edit names.dmp file into a file only containing scientific names
		# sed "s/ <[a-zA-Z -,.&:'0-9]*>//g" names.dmp | grep 'scientific name' | cut -f 1,3 | awk -F $'\t' ' { t = $1; $1 = $2; $2 = t; print; } ' OFS=$'\t' | grep -v 'environmental' | grep -v 'uncultured' | grep -v 'unidentified' | grep -v 'metagenome' > NCBI_staxids_scientific.txt
			# 1. Remove <genus>, <family>, and other strings in <> brackets from taxonomy (otherwise the NCBI taxonomy won't match the SILVA taxonomy)
			# 2. Extract only scientific names and staxids
			# 3. Cut out columns we need
			# 4. Invert columns for script to work
			# 5. Removes lines containing "environmental", "uncultured", "unidentified", and "metagenome"
				# Needed because
					# SILVA taxonomy can have the same taxonomic ranks (e.g., "environmental sample") for different higher ranks (e.g., "nematode; environmental sample" and "bacteria;environmental sample"), wich would, however, be assigned to the same staxid because the lower rank "environmental sample" is similar
					# NCBI taxonomy can different staxids for the same taxonomic name, which will cause issue when matching
		# We match SILVA taxonomy against this file (against scientific names) first
	# Edit names.dmp file into a file only containing non-scientific names
		# sed "s/ <[a-zA-Z -,.&:'0-9]*>//g" names.dmp | grep -v 'scientific name' | cut -f 1,3 | awk -F $'\t' ' { t = $1; $1 = $2; $2 = t; print; } ' OFS=$'\t' | grep -v 'environmental' | grep -v 'uncultured' | grep -v 'unidentified' | grep -v 'metagenome' > NCBI_staxids_non_scientific.txt
			# 1. Remove <genus>, <family>, and other strings in <> brackets from taxonomy (otherwise the NCBI taxonomy won't match the SILVA taxonomy)
			# 2. Extract only non-scientific names and staxids
			# 3. Cut out columns we need
			# 4. Invert columns for script to work
			# 5. Removes lines containing "environmental", "uncultured", "unidentified", and "metagenome"
				# Needed because
					# SILVA taxonomy can have the same taxonomic ranks (e.g., "environmental sample") for different higher ranks (e.g., "nematode; environmental sample" and "bacteria;environmental sample"), wich would, however, be assigned to the same staxid because the lower rank "environmental sample" is similar
					# NCBI taxonomy can different staxids for the same taxonomic name, which will cause issue when matching
		# If SILVA taxonomy is not in exact scientific names, then we match against these to check for synonyms etc.


import csv,sys

# Set variable names
NCBI_scientific_input=sys.argv[1]
NCBI_non_scientific_input=sys.argv[2]
SILVA_input=sys.argv[3]
output_name=sys.argv[4]

# Read in NCBI scientific names file as dictionary
NCBI_scientific = open(NCBI_scientific_input,'r')
NCBI_scientific_lower = (line.lower() for line in NCBI_scientific) # Sets all file content to lowercase, so that matching of the files later is not depending on upper- or lowercase)
reader1=csv.reader(NCBI_scientific_lower, delimiter='\t')
NCBI_scientific_dict={}
for row in reader1:
	NCBI_scientific_dict[row[0]]=row[1]

# Read in NCBI non-scientific names file as dictionary
NCBI_non_scientific = open(NCBI_non_scientific_input,'r')
NCBI_non_scientific_lower = (line.lower() for line in NCBI_non_scientific) # Sets all file content to lowercase, so that matching of the files later is not depending on upper- or lowercase)
reader2=csv.reader(NCBI_non_scientific_lower, delimiter='\t')
NCBI_non_scientific_dict={}
for row in reader2:
	NCBI_non_scientific_dict[row[0]]=row[1]

# Read in SILVA file as dictionary
SILVA = open(SILVA_input,'r')
SILVA_lower = (line.lower() for line in SILVA) # Sets all file content to lowercase, so that matching of the files later is not depending on upper- or lowercase)
reader3=csv.reader(SILVA_lower, delimiter='\t')
SILVA_dict={}
for row in reader3:
	SILVA_dict[row[0]]=row[1]

# Split up SILVA taxonomy and invert it
for key,value in SILVA_dict.items():
	SILVA_dict[key] = value.split(";")[::-1]

# Loop SILVA taxonomy dictionary over NCBI taxonomy dictionary for each line and match with NCBI staxid when a hit is found
output_dict={} # Make empty dictionary for matching lines
for key,value in SILVA_dict.items():
	l=0
	while l < len(value):
		if value[l] in NCBI_scientific_dict:
			output_dict[key.upper()]=NCBI_scientific_dict[value[l]]
			break
		elif value[l] in NCBI_non_scientific_dict:
			output_dict[key.upper()]=NCBI_non_scientific_dict[value[l]]
			break
		else:
			output_dict[key.upper()]='0'
			l += 1

# Saves the merged dictionary in a defined output file, delimited by tab
with open(output_name, 'w') as f:
    for key in output_dict.keys():
        f.write("%s\t%s\n"%(key,output_dict[key]))