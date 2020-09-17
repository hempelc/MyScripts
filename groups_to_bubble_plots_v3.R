library(dplyr)
library(data.table)
library(ggplot2)
library(viridis)
library(vegan)

# Setting WD
workfolder <- "/Users/christopherhempel/Desktop"
setwd(workfolder)

# Reading in data and generating general tables
filename <- "CREST_BWA_final.txt"
data <- fread(filename, data.table=T, sep="\t")
tax <- select(data, superkingdom:genus) # Right now no species are picked because the information is kind of unequally organized
spe <- data[[18]]

# Creating taxlist vector with phylum per row in taxonomy table (or if phylum = NA, then superkingdom)
taxlastrow <- nrow(tax)
taxlist <- rep(NA,nrow(tax))
for (i in 1:nrow(tax))
{ if (tax[i,1] == "Unknown")
{ taxlist[i] <- tax[i,1] }
  else if (is.na(tax[i,3]) == TRUE)
  { taxlist[i] <- paste(tax[i,1], ": Unknown", sep="") }
  else
  { taxlist[i] <- paste(tax[i,1], ": ", tax[i,3], sep="") }
}

# Combine read count and taxonomic group information and aggregate based on groups
plot_table <- as.data.table(cbind(taxlist,spe))
plot_agg <- aggregate(unlist(plot_table[[2]])~unlist(plot_table[[1]]),data=plot_table,FUN=sum)
colnames(plot_agg) <- c("Group", "Reads")
plot_agg_ordered <- plot_agg[order(as.character(plot_agg$Group)),]
plot_agg_ordered$Group <- factor(plot_agg_ordered$Group, levels=plot_agg_ordered$Group)

# Set color for plots
viridis_colors <- viridis_pal(option = "D")(nrow(plot_agg_ordered)) # Choosing viridis colors (colorblindfriendly), as many colors from gradient as numbers of groups
set.seed(002)
colorvec1 <- sample(viridis_colors) # Randomize color order, otherwise bars next to each other are hard to distinguish
colorvec2 <- c("#023fa5", "#7d87b9", "#bec1d4", "#d6bcc0", "#bb7784", "#8e063b", "#11c638", "#8dd593", "#c6dec7", "#ead3c6", "#f0b98d", "#ef9708", "#0fcfc0", "#9cded6", "#d5eae7", "#f3e1eb", "#f6c4e1", "#f79cd4", "#4a6fe3", "#8595e1", "#b5bbe3", "#e6afb9", "#e07b91", "#d33f6a")
colorvec3 <- c("#72d5de","#eca9b0","#7fe1cf","#e1b0dd","#aad9a7","#74aff3","#c6d494","#b9b5f3","#ebc491","#7bc2f1","#dac6a3","#8bd0eb","#94dcba","#b6bee4","#acd8ba","#86bcb1","#afe6db")

# Plot one sample (the actual one, test)
plot1<-ggplot(data=plot_agg_ordered, aes(x=Group, y=Reads, fill=Group))+
  geom_bar(stat="identity", color="black")+
  geom_text(aes(label=Reads), vjust=-0.8, size=3)+
  theme_minimal()+
  scale_fill_manual(values=colorvec1)+
  ylim(0,1.1*max(plot_agg_ordered$Reads))+
  theme(legend.key.size = unit(1,"line"))+
  theme(axis.text.x=element_blank())+
  theme(legend.position="bottom")+
  theme(legend.text=element_text(size=11))+
  theme(legend.title=element_blank())
plot1
ggsave("Plot.png", plot=plot1,  device="png",  width=240, units="mm")

# Create new random samples for stacked barplot test
sample_2 <- round(runif(nrow(plot_agg_ordered), 0, max(plot_agg_ordered$Reads)))
sample_3 <- round(runif(nrow(plot_agg_ordered), 0, max(plot_agg_ordered$Reads)))
sample_4 <- round(runif(nrow(plot_agg_ordered), 0, max(plot_agg_ordered$Reads)))
sample_5 <- round(runif(nrow(plot_agg_ordered), 0, max(plot_agg_ordered$Reads)))
sample_6 <- round(runif(nrow(plot_agg_ordered), 0, max(plot_agg_ordered$Reads)))
test_table <- as.data.frame(cbind(plot_agg_ordered[[2]],sample_2,sample_3,sample_4,sample_5,sample_6))
test_relative <- cbind(plot_agg_ordered$Group, decostand(test_table, "total", 2))
colnames(test_relative) <- c("Group", "SPAdes: Bowtie2" ,"SPAdes: BWA" ,"IDBA-UD: Bowtie2", "IDBA-UD: BWA" ,"Megahit: Bowtie2", "Megahit: BWA")

# Transform dataset for stacked barplots and plot
test_stacked_plot <- melt(test_relative,id.vars = "Group", variable.name="Combination", value.name="Reads")

plot2<-ggplot(data=test_stacked_plot, aes(x=Combination, y=Reads, fill=Group))+
  geom_bar(stat="identity")+
  theme_minimal()+
  scale_fill_manual(values=colorvec1)+
  theme(legend.key.size = unit(1,"line"))+
  theme(legend.position="bottom")+
  theme(legend.text=element_text(size=11))+
  theme(legend.title=element_blank())
plot2
ggsave("Plot2.png", plot=plot2,  device="png",  width=240, units="mm")

#Experiment with separated bars
melted <- test_stacked_plot
melted$Category <- c(rep("SPAdes", 34), rep("IDBA-UD", 34), rep("Megahit", 34))
melted$Combination <- c(rep(c(rep("Bowtie2", 17), rep("BWA", 17)), 3))

plot3<-ggplot(melted, aes(x = Combination, y = Reads, fill = Group))+
  #geom_bar(stat = 'identity', position = 'stack', colour="black")+
  geom_bar(stat = 'identity', position = 'stack')+
  facet_grid(~ Category, scales = "free", space = "free")+
  theme_minimal()+
 scale_fill_manual(values=colorvec3[1:nrow(melted)])+
  #scale_fill_manual(values=colorvec1)+
  # scale_fill_manual(values=viridis_colors)+
  theme(legend.key.size = unit(1,"line"))+
  theme(legend.position="bottom")+
  theme(legend.text=element_text(size=11))+
  theme(legend.title=element_blank())
plot3
ggsave("Plot8.png", plot=plot3,  device="png",  width=240, units="mm")
