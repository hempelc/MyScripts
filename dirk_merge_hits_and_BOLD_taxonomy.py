#!/usr/bin/env python3

# usage: ./merge_files.py raw_hit_table.csv vascan_ids.txt output_file_name

import pandas as pd, sys

df1_name="Raw_Hit_Table_Megan.csv"
df2_name="Insecta_COI_GenBank_tax.txt"
output_name="Raw_Hit_Table_Megan_chris.csv"

# xls = pd.ExcelFile(df1_name)
# df1 = pd.read_excel(xls, "P94_1.00")
df1 = pd.read_csv(df1_name)
df2 = pd.read_csv(df2_name, sep=';')
df3 = pd.merge(df1, df2, left_on="ID", right_on="Process ID", how='left')
df4 = df3.drop("Process ID", axis=1)
df4.to_csv(output_name, sep=',', na_rep='NA', index=False)
