#!/usr/bin/python

import pandas as pd, sys

df1_name=sys.argv[1]
output_name=sys.argv[2]

df1 = pd.read_csv(df1_name, sep='\t', index_col=False, keep_default_na=False)
df2 = df1.drop(columns=['sequence'])
#df2 = df1.drop(columns=['sequence','size'])
counts=[]
for i in range(len(df2)):
    NAs=0
    for j in range(len(df2.columns)):
        if df2.iat[i,len(df2.columns)-1-j] == "NA":
            NAs+=1
            continue
        else:
            break
    counts.append(NAs)
#counts=pd.DataFrame.count(df2, axis='columns')
LCA=[]
LCA_rank=[]
for i in range(len(df2)):
    if counts[i] == len(df2.columns):
        LCA.append("NA")
        LCA_rank.append("NA")
    else:
        LCA.append(df2.iat[i,len(df2.columns)-1-counts[i]])
        LCA_rank.append(df2.columns[len(df2.columns)-1-counts[i]])
df1['LCA']=LCA
df1['LCA_rank']=LCA_rank
df1.to_csv(output_name, sep='\t', na_rep='NA', index=False)
