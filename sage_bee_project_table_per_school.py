import pandas as pd
import csv
import numpy as np

file_name="/Users/christopherhempel/Desktop/Sage-2020rbcL"
df = pd.read_excel(file_name + ".xlsx", "Sheet1")
df_cut=df[["Order", "Family", "Genus"]].groupby(["Order", "Family", "Genus"]).size().reset_index()

master_list=[["Order", "Family", " Genus", "School"]]
for index, row in df_cut[["Order", "Family", "Genus"]].iterrows():
    order=row["Order"]
    family=row["Family"]
    genus=row["Genus"]
    for i in df.iloc[:, 7:-1:]:
        if not df.loc[(df['Order'] == order) & (df['Family'] == family) & (df['Genus'] == genus) & (df[i] != 0)].empty:
            list=[order, family, genus, i]
            list.extend(df.loc[(df['Order'] == order) & (df['Family'] == family) & (df['Genus'] == genus) & (df[i] != 0)]["Species"].unique().tolist())
            master_list.append(list)

with open(file_name + "_chris.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerows(master_list)
