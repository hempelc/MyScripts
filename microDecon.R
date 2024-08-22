library("microDecon")
library("dplyr")
library("readxl")
library("arrow")
library("tools")

# Path to ESV/OTU file
file <- "/Users/christopherhempel/Desktop/Simplex/sequencing runs/6 Nov 2023/16S/taxonomy/simplex-16s_apscale_OTU_table_filtered.parquet.snappy"
# Adapt abbreviations for samples and neg controls as necessary (=sub-strings that need to be contained in all sample/negativ control names)
#sample_abbr <- paste("BH", "POS", sep = "|")
sample_abbr <- "^RSDEW\\d+$"
neg_abbr <- paste("EXC", "NEG", sep = "|")
#neg_abbr <- "negative"
# OTUs or ESVs?
unit="OTU"

# Import data
fileformat <- file_ext(file)
if (fileformat=="snappy") {
  fileformat <- "parquet.snappy"
}
if (fileformat=="xlsx") {
  df <- as.data.frame(read_excel(file))
  rownames(df) <- df[, 1]
  df <- df[, -1]
} else if (fileformat=="csv") {
  df <- read.csv(file, row.names = 1)
} else if (fileformat=="parquet.snappy") {
  df <- as.data.frame(read_parquet(file))
  rownames(df) <- df[, 1]
  df <- df[, -1]
} else {
  print("File format must be xlsx, csv, or parquet.snappy.")
}

# Identify samples and neg controls
neg_controls <- names(df)[grep(neg_abbr, names(df))]
true_samples <- names(df)[grep(sample_abbr, names(df))]
#true_samples <- colnames(df)[1:11]
samples <- c(neg_controls, true_samples)

# Generate sample df and format for microDecon
df_samples <- df[samples]
df_samples$ID <- rownames(df_samples)
rownames(df_samples) <- NULL
df_samples <- df_samples[c("ID", names(df_samples)[-ncol(df_samples)] )]

# Separating other information
df_other <- df %>%
  select(-any_of(samples))

# Decontamination function
# Note: we can specify different groups of samples with numb.ind, but we only have one group, so this is set to the number of samples
decon_results <- decon(data=df_samples, numb.blanks=length(neg_controls), numb.ind=c(length(true_samples)),taxa=F) # taxa=F because the last column does not contain tax information

# Save filtered df
df_samples_decon <- decon_results$decon.table

# Merge reads and other data
df_other$ID <- rownames(df_other)
df_decon <- merge(df_samples_decon, df_other, by = "ID")

# Restore OTU order
df_decon$NumericValues <- as.numeric(gsub(paste0(unit, "_"), "", df_decon$ID))
df_decon <- df_decon[order(df_decon$NumericValues), ]
df_decon <- df_decon[, -ncol(df_decon)]

# Delete negative control column
df_decon <- df_decon[, -2]

# Export df
outfile <- gsub(paste0("\\.", fileformat, "$"), "_microdecon-filtered.csv", file)
write.csv(df_decon, outfile, row.names = FALSE)
