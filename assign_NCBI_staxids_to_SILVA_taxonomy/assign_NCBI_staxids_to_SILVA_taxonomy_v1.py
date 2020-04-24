#!/usr/bin/python

# Version 1.0, made on 3rd Apr 2020 by Chris Hempel (hempelc@uoguelph.ca)

# Usage: ./SILVA_to_NCBI_taxonomy.py NCBI_staxids_file SILVA_taxonomy_file output_file_name

# Merges SILVA taxonomy names with NCBI staxids

# SILVA taxonomy file needs to have two columns, one with Accession number and one with taxonomy
# NCBI taxonomy file needs to have two columns, one with staxid and one with taxonomy


import csv,sys

# Set variable names
file1=sys.argv[1]
file2=sys.argv[2]
output_name=sys.argv[3]

# Read in first file as dictionary
table1 = open(file1,'r')
table1_lower = (line.lower() for line in table1) # Sets all file content to lowercase, so that matching of the files later is not depending on upper- or lowercase)
reader1=csv.reader(table1_lower, delimiter='\t')
table1_dict={}
for row in reader1:
	table1_dict[row[0]]=row[1]

# Read in second file as dictionary
table2 = open(file2,'r')
table2_lower = (line.lower() for line in table2) # Sets all file content to lowercase, so that matching of the files later is not depending on upper- or lowercase)
reader2=csv.reader(table2_lower, delimiter='\t')
table2_dict={}
for row in reader2:
	table2_dict[row[0]]=row[1]

# Split up SILVA taxonomy and invert it
for key,value in table2_dict.items():
	table2_dict[key] = value.split(";")[::-1]

# Loop SILVA taxonomy dictionary over NCBI taxonomy dictionary for each line and match with NCBI staxid when a hit is found
table3_dict={}
exceptions=["environmental", "uncultured", "unidentified", "metagenome"] # when exception are found in SILVA taxonomy, the respective rank is skipped
for key,value in table2_dict.items():
	l=0
	while l <= len(table2_dict[key]):
		for exception in value[l].split(" "):
			if exception in exceptions:
				l += 1
				continue
		if value[l] in table1_dict:
			table3_dict[key]=table1_dict[value[l]]
			break
		else:
			table3_dict[key]='NA'
			l += 1

# Saves the merged dictionary in a defined output file, delimited by tab
with open(output_name, 'w') as f:
    for key in table3_dict.keys():
        f.write("%s\t%s\n"%(key,table3_dict[key]))
