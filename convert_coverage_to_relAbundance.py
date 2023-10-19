import pandas as pd

file = f"/Users/christopherhempel/Desktop/KAUST_student_work/elisa/deepseep/kraken2_deepseep/RSDE_{i}_assembly_and_taxonomy.csv"
df = pd.read_csv(file)
df["covered_bases"] = df["contigLength"] * df["coverage"]
df_small = df[
    [
        "superkingdom",
        "phylum",
        "class",
        "order",
        "family",
        "genus",
        "species",
        "covered_bases",
        "contigLength",
    ]
]

df_agg = (
    df_small.groupby(list(df_small.columns)[:-2])[["covered_bases", "contigLength"]]
    .sum()
    .reset_index()
)
#### Determine average per-base coverage for each taxon
df_agg["per_base_coverage"] = df_agg["covered_bases"] / df_agg["contigLength"]
df_agg = df_agg.drop(["contigLength", "covered_bases"], axis=1)
#### Turn coverages into relative abundances:
df_agg["per_base_coverage"] = (
    df_agg["per_base_coverage"] / df_agg["per_base_coverage"].sum()
)
### Rename counts col
df_agg.rename(columns={"per_base_coverage": "rel_abun"}, inplace=True)
df_agg = df_agg.sort_values("rel_abun", ascending=False)
df_agg.to_csv(
    f"/Users/christopherhempel/Desktop/KAUST_student_work/elisa/deepseep/kraken2_deepseep/RSDE_{i}_assembly_and_taxonomy_abudance.csv",
    index=False,
)
