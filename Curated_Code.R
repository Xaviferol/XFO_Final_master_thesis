# Script fo the final master thesis named "Activity dependent transcription pathways and its implication in Alzheimer's Disease" written by Xavier Fernandez Olalla.

#Session information:
#R version 4.1.1 (2021-08-10)
#Platform: x86_64-w64-mingw32/x64 (64-bit)
#Running under: Windows 10 x64 (build 19044

## RAW DATA QUALITY CONTROL ##
#Raw data obtention was performed manually, selecting different samples from six different studies.
#Raw data quality control was performed using the package "fastqcr"

library("fastqcr")
fastqc_install() 
fastqc(fq.dir = "./Mm/sin_trimmed/",qc.dir = "./Mm/sin_trimmed/FASTQC/")  #Here we indicate the directory where is the raw data and the directory where we want to export the quality control analysis
qc <- qc_aggregate("./Mm/sin_trimmed/FASTQC/") # aggregate all the info to make an overall analysis
summary(qc)
#This step was performed with all the datasets of raw data. But only one of the mice model studies was not curated.
#Filtering was performed by "Fastp" as indicated in the memory. 

# Once trimmed, mm2 data was re-analyzed:
fastqc(fq.dir = "./Mm/trimmed/",qc.dir = "./Mm/trimmed/FASTQC/")  
qc2 <- qc_aggregate("./Mm/trimmed/FASTQC/") 
summary(qc2)
#Now all data was curated

## INDEXING AND ALIGNMENT ##
# For the alignment Rsubread package was used. 
library(Rsubread)
# Rsubread package align by first indexing all the genome, this is a high computing costing order, but the posterior alignment is quicker. 
buildindex(
  basename="hg38", #the name of the genome we will use
  reference="./Genomas/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz", # dir. to the reference genome we will use. In this case the human Hg38
  # details of the index
  gappedIndex = FALSE, #full single-block indexed. 
  indexSplit = FALSE,
  memory=50000, # Ram capacity used for the indexing
  TH_subread = 100, # threshold of repetitive 16mers
  colorspace = FALSE) #indexed in a blank block.

#this one for the mouse samples
buildindex(
  basename="mm39",
  reference="./Genomas/Mus_musculus.GRCm39.dna.primary_assembly.fa.gz",
  gappedIndex = FALSE,
  indexSplit = FALSE,
  memory=50000,
  Tm_subread = 100, 
  colorspace = FALSE)

# Once we have the indexed genomes, can align the read counts. 
# to speed up the process, I made calling lists of fastq files and outputs and then, ordered the alignment, mapping and sorting of counts:

# cc1 and cc2 (single end reads)
c_fastq.files <- list.files(path = "./Cc/FastQfiles",pattern = ".fastq", full.names = TRUE) # only one fastq file per sample
c_BAM.files <- sub("/FastQfiles", "/BAM_files", c_fastq.files)
c_BAM.files <- sub(".fastq.gz", ".bam", c_BAM.files)
c_sorted_BAM.files <- sub("1C", "1c_Sorted", c_BAM.files)
c_sorted_BAM.files <- sub("2C", "2c_Sorted", c_sorted_BAM.files)
c_sorted_BAM.files <- sub("/BAM_files/", "/BAM_files/Sorted/", c_sorted_BAM.files)
c_sorted_BAM.files <- sub(".bam", "", c_sorted_BAM.files)


# hs1 dataset (paired end reads)
h1_fastq.files_1 <- list.files(path = "./Hs/FastQfiles",pattern = "_1.fastq", full.names = TRUE) #here I call the first paired end reads
h1_fastq.files_2 <- list.files(path = "./Hs/FastQfiles",pattern = "_2.fastq", full.names = TRUE) # here I call the second paired end reads
h1_fastq.files <- sub("_1.fastq.gz", ".fastq.gz", h1_fastq.files_1)
h1_BAM.files <- sub("/FastQfiles", "/BAM_files", h1_fastq.files) #here I produce the export BAM files 
h1_BAM.files <- sub(".fastq.gz", ".bam", h1_BAM.files) 

# hs2 dataset (single end reads)
h2_fastq.files <- list.files(path = "./Hs/FastQfiles",pattern = "2h", full.names = TRUE) 
h2_BAM.files <- sub("/FastQfiles", "/BAM_files", h2_fastq.files)
h2_BAM.files <- sub(".fastq.gz", ".bam", h2_BAM.files)

# mm1 dataset (paired end reads)
m1_fastq.files_1 <- list.files(path = "./Mm/FastQfiles",pattern = "_1.fastq", full.names = TRUE)
m1_fastq.files_2 <- list.files(path = "./Mm/FastQfiles",pattern = "_2.fastq", full.names = TRUE)
m1_fastq.files <- sub("_1.fastq.gz", ".fastq.gz", m1_fastq.files_1)
m1_BAM.files <- sub("/FastQfiles", "/BAM_files", m1_fastq.files)
m1_BAM.files <- sub(".fastq.gz", ".bam", m1_BAM.files)

# mm2 dataset (single end reads)
m2_fastq.files <- list.files(path = "./Mm/FastQfiles",pattern = "2m", full.names = TRUE)
m2_BAM.files <- sub("/FastQfiles", "/BAM_files", m2_fastq.files)
m2_BAM.files <- sub(".fastq.gz", ".bam", m2_BAM.files)

#Once had all prepared, I ran all the mapping code in a computing server:
#For alignment, I used the align function
# cc1 and cc2 
align("hg38", # indicate the builded genome where we want to map
      readfile1=c_fastq.files, # the file (or list of files) that are going to be mapped
      input_format = "FASTQ",
      output_format = "BAM",
      output_file = c_BAM.files) #file (or list of files) for the output BAM files


# Then, once all fastq files were aligned, sorting is essential for later analysis
# I created a list like in previous steps:
c_sorted_BAM.files <- sub("1C", "1c_Sorted", c_BAM.files)
c_sorted_BAM.files <- sub("2C", "2c_Sorted", c_sorted_BAM.files)
c_sorted_BAM.files <- sub("/BAM_files/", "/BAM_files/Sorted/", c_sorted_BAM.files)
c_sorted_BAM.files <- sub(".bam", "", c_sorted_BAM.files)

for (i in 1:length(c_BAM.files)) { #the sortBam function cannot compute over a list, so I did a loop for every sample.
  sortBam(c_BAM.files[i],c_sorted_BAM.files[i]) # the sort bam need the imput BAM file and the output sorted bam file
}

# Then I repeated this procedure with human and mice samples:
# hs1
align("hg38",
      readfile1=h1_fastq.files_1,
      readfile2=h1_fastq.files_2,
      input_format = "FASTQ",
      output_format = "BAM",
      output_file = h1_BAM.files)

# hs2
align("hg38",
      readfile1=h2_fastq.files,
      input_format = "FASTQ",
      output_format = "BAM",
      output_file = h2_BAM.files)

h_BAM.files <- list.files(path = "./Hs/BAM_files",pattern = ".bam$", full.names = TRUE)
h_sorted_BAM.files <- sub("1h", "1h_Sorted", h_BAM.files)
h_sorted_BAM.files <- sub("2h", "2h_Sorted", h_sorted_BAM.files)
h_sorted_BAM.files <- sub("/BAM_files/", "/BAM_files/Sorted/", h_sorted_BAM.files)
h_sorted_BAM.files <- sub(".bam", "", h_sorted_BAM.files)

for (i in 1:length(h_BAM.files)) {
  sortBam(h_BAM.files[i],h_sorted_BAM.files[i])
}

# mm1
align("mm39",
      readfile1=m1_fastq.files_1,
      readfile2=m1_fastq.files_2,
      input_format = "FASTQ",
      output_format = "BAM",
      output_file = m1_BAM.files)

# mm2
align("mm39",
      readfile1=m2_fastq.files_1,
      readfile2=m2_fastq.files_2,
      input_format = "FASTQ",
      output_format = "BAM",
      output_file = m2_BAM.files)


m_BAM.files <- list.files(path = "./Mm/BAM_files",pattern = ".bam$", full.names = TRUE)
m_sorted_BAM.files <- sub("1m", "1m_Sorted", m_BAM.files)
m_sorted_BAM.files <- sub("2m", "2m_Sorted", m_sorted_BAM.files)
m_sorted_BAM.files <- sub("/BAM_files/", "/BAM_files/Sorted/", m_sorted_BAM.files)
m_sorted_BAM.files <- sub(".bam", "", m_sorted_BAM.files)

for (i in 1:length(m_BAM.files)) {
  sortBam(m_BAM.files[i],m_sorted_BAM.files[i])
}


## COUNTING READS TO GENES ##
# To counting reads to genes, the Featurecounts of Rsubread package was used:

# First I summarized all the samples of each dataset to produce a single sheet with all the samples per study:

Analysis_files_c1 <- list.files(path="./Cc/BAM_files/Sorted", pattern= "1c",full.names= TRUE)
Analysis_files_c2 <- list.files(path="./Cc/BAM_files/Sorted", pattern= "2c",full.names= TRUE)

Analysis_files_h1 <- list.files(path="./Hs/BAM_files/Sorted", pattern= "1h",full.names= TRUE)
Analysis_files_h2 <- list.files(path="./Hs/BAM_files/Sorted", pattern= "2h",full.names= TRUE)

Analysis_files_m1 <- list.files(path="./Mm/BAM_files/Sorted", pattern= "1m",full.names= TRUE)
Analysis_files_m2 <- list.files(path="./Mm/BAM_files/Sorted", pattern= "2m",full.names= TRUE)

#Then all genes were counted:

fc_cc1 <-featureCounts(Analysis_files_c1, annot.inbuilt="hg38",isPairedEnd = FALSE) #For this function BAM files, the indexed genome, and the type of read have to be indicated.
fc_cc2 <-featureCounts(Analysis_files_c2, annot.inbuilt="hg38",isPairedEnd = FALSE)
write.table(fc_cc1$counts,"./Cc/FC/fc_cc1.csv")
write.table(fc_cc2$counts,"./Cc/FC/fc_cc2.csv")

fc_hs1 <-featureCounts(Analysis_files_h1, annot.inbuilt="hg38",isPairedEnd = TRUE)
fc_hs2 <-featureCounts(Analysis_files_h2, annot.inbuilt="hg38",isPairedEnd = FALSE)
write.table(fc_hs1$counts,"./Hs/FC/fc_hs1.csv")
write.table(fc_hs2$counts,"./Hs/FC/fc_hs2.csv")

fc_mm1 <-featureCounts(Analysis_files_m1, annot.inbuilt="mm39",isPairedEnd = TRUE)
fc_mm2 <-featureCounts(Analysis_files_m2, annot.inbuilt="mm39",isPairedEnd = TRUE)
write.table(fc_mm1$counts,"./Mm/FC/fc_mm1.csv")
write.table(fc_mm2$counts,"./Mm/FC/fc_mm2.csv")

# At this point. I have the counts of each gene per each sample. Next step is perform Differential Expression Analysis (DGE).

## DGE ##

# To perform DGE I will use the r package Deseq2 that is based on the negative binomial distribution
# Deseq2 creates and uses a matrix to perform DGE analysis:

# cc1
dc_cc1<- read.table("fc_cc1.csv",sep = ";", header=TRUE, row.names = 1) #First we have to import the data counts obtained from counting.
sn_cc1<- read.table("sn_cc1.txt",sep = "", header=TRUE,row.names = 1) #A part of the data counts, Deseq2 needs the samples information that will use to perform the group comparisons. 
# In this case the sample information was:
#   Treatment
# Control_1	  Untreated
# Control_2	  Untreated
# Control_3	  Untreated
# Depol_1 	Depol
# Depol_2	  Depol
# Depol_3	  Depol

colnames(dc_cc1)<-rownames(sn_cc1) #To perform the analysis we have to be sure that the name and order of the samples match in both files
all(colnames(dc_cc1) == rownames(sn_cc1))

# Then generate the matrix that will be used by Deseq2
cc1_Deseq<- DESeqDataSetFromMatrix(countData = dc_cc1, # gene counts data
                                   colData = sn_cc1, # sample data
                                   design = ~ Treatment) # Here indicate the column that will be used to perform the comparisons to ibtain the DEGs (differential gene expression). 
#In this case there's only 1, but if there were more conditions, here would select the condition you want to compare.

cc1_Deseq$Treatment <- relevel(cc1_Deseq$Treatment, ref = "Untreated") #Here the reference factor of the condition is selected. This factor will be the control and the other factors will be over or under expressed in comparison with the reference one.
cc1_dds <- DESeq(cc1_Deseq) # this is the function that performs the analysis: estimation of size factors, estimation of dispersion, Negative Binomial GLM fitting and Wald statistics
cc1_Results <- results(cc1_dds) #then we get the results, where we have the genes, the log2foldchange  between conditions

# in the results of Deseq2, the only information of genes is the GENEID, so I used the org.Hs.eg.db package to get more information:
annotations_orgDb <- AnnotationDbi::select(org.Hs.eg.db, # database
                                           keys = rownames(cc1_Results),  # data to use for retrieval
                                           columns = c("SYMBOL","MAP","GENENAME"), # information to retreive for given data
                                           keytype = "ENTREZID") # type of data given in 'keys' argument
t1 <- annotations_orgDb %>% distinct(ENTREZID, .keep_all = TRUE) #some anotations were duplicated, here they are cleaned
cc1_finalData<- cbind(t1,cc1_Results) # bind the information about the genes and the information about differentially expressed.
write.csv(as.data.frame(cc1_finalData), file="DGE_cc1.csv") #final list of DGE results.

# cc2
dc_cc2<- read.table("fc_cc2.csv",sep = ";", header=TRUE, row.names = 1)
sn_cc2<- read.table("sn_cc2.txt",sep = "", header=TRUE,row.names = 1)
colnames(dc_cc2)<-rownames(sn_cc2)
cc2_Deseq<- DESeqDataSetFromMatrix(countData = dc_cc2,
                                   colData = sn_cc2,
                                   design = ~ Treatment)
cc2_Deseq$Treatment <- relevel(cc2_Deseq$Treatment, ref = "Untreated")
cc2_dds <- DESeq(cc2_Deseq)
cc2_Results <- results(cc2_dds)
annotations_orgDb <- AnnotationDbi::select(org.Hs.eg.db, 
                                           keys = rownames(cc2_Results),  
                                           columns = c("SYMBOL","MAP","GENENAME"),
                                           keytype = "ENTREZID") 
t1 <- annotations_orgDb %>% distinct(ENTREZID, .keep_all = TRUE)
cc2_finalData<- cbind(t1,cc2_Results)
write.csv(as.data.frame(cc2_finalData), file="DGE_cc2.csv")

# hs1
dc_hs1<- read.table("fc_hs1.csv",sep = ";", header=TRUE, row.names = 1)
sn_hs1<- read.table("sn_hs1.txt",sep = "", header=TRUE,row.names = 1)
colnames(dc_hs1)<-rownames(sn_hs1)
hs1_Deseq<- DESeqDataSetFromMatrix(countData = dc_hs1,
                                   colData = sn_hs1,
                                   design = ~ Group)
hs1_Deseq$Group <- relevel(hs1_Deseq$Group, ref = "Control")
hs1_dds <- DESeq(hs1_Deseq)
hs1_Results <- results(hs1_dds)
annotations_orgDb <- AnnotationDbi::select(org.Hs.eg.db, # database
                                           keys = rownames(hs1_Results), 
                                           columns = c("ENTREZID","SYMBOL","GENENAME"), 
                                           keytype = "ENTREZID") 
t1 <- annotations_orgDb %>% distinct(ENTREZID, .keep_all = TRUE)
hs1_finalData<- cbind(t1,hs1_Results)
write.csv(as.data.frame(hs1_finalData), file="DGE_hs1.csv")

# hs2
dc_hs2<- read.table("fc_hs2.csv",sep = ";", header=TRUE, row.names = 1)
sn_hs2<- read.table("sn_hs2.txt",sep = "", header=TRUE,row.names = 1)
colnames(dc_hs2)<-rownames(sn_hs2)
hs2_Deseq<- DESeqDataSetFromMatrix(countData = dc_hs2,
                                   colData = sn_hs2,
                                   design = ~ Group)
hs2_Deseq$Group <- relevel(hs2_Deseq$Group, ref = "Control")
hs2_dds <- DESeq(hs2_Deseq)
hs2_Results <- results(hs2_dds)
summary(hs2_Results)
annotations_orgDb <- AnnotationDbi::select(org.Hs.eg.db, # database
                                           keys = rownames(hs2_Results),  
                                           columns = c("ENTREZID","SYMBOL","GENENAME"), 
                                           keytype = "ENTREZID") 
t1 <- annotations_orgDb %>% distinct(ENTREZID, .keep_all = TRUE)
hs2_finalData<- cbind(t1,hs2_Results)
write.csv(as.data.frame(hs2_finalData), file="DGE_hs2.csv")

# mm1
dc_mm1<- read.table("fc_mm1.csv",sep = ";", header=TRUE, row.names = 1)
sn_mm1<- read.table("sn_mm1.txt",sep = "", header=TRUE,row.names = 1)
colnames(dc_mm1)<-rownames(sn_mm1)
mm1_Deseq<- DESeqDataSetFromMatrix(countData = dc_mm1,
                                   colData = sn_mm1,
                                   design = ~ Genotype)
mm1_Deseq$Genotype <- relevel(mm1_Deseq$Genotype, ref = "WT")
mm1_dds <- DESeq(mm1_Deseq)
mm1_Results <- results(mm1_dds)
mm_annotations_orgDb <- AnnotationDbi::select(org.Mm.eg.db, 
                                              keys = rownames(mm1_Results),  
                                              columns = c("ENTREZID","SYMBOL","GENENAME"), 
                                              keytype = "ENTREZID") 
t1 <- mm_annotations_orgDb %>% distinct(ENTREZID, .keep_all = TRUE)
mm1_finalData<- cbind(t1,mm1_Results)
write.csv(as.data.frame(mm1_finalData), file="DGE_mm1.csv")

# mm2
dc_mm2<- read.table("fc_mm2.csv",sep = ";", header=TRUE, row.names = 1)
sn_mm2<- read.table("sn_mm2.txt",sep = "", header=TRUE,row.names = 1)
colnames(dc_mm2)<-rownames(sn_mm2)
mm2_Deseq<- DESeqDataSetFromMatrix(countData = dc_mm2,
                                   colData = sn_mm2,
                                   design = ~ Genotype)
mm2_Deseq$Genotype <- relevel(mm2_Deseq$Genotype, ref = "WT")
mm2_dds <- DESeq(mm2_Deseq)
mm2_Results <- results(mm2_dds)
mm_annotations_orgDb <- AnnotationDbi::select(org.Mm.eg.db, 
                                              keys = rownames(mm2_Results),  
                                              columns = c("ENTREZID","SYMBOL","GENENAME"), 
                                              keytype = "ENTREZID") 
t1 <- mm_annotations_orgDb %>% distinct(ENTREZID, .keep_all = TRUE)
mm2_finalData<- cbind(t1,mm2_Results)
write.csv(as.data.frame(mm2_finalData), file="DGE_mm2.csv")


# At this point. All the DEGs of all samples are obtained. From some datasets, few or none DEG have been obtained:
#	5101 DEG from cc1 dataset
#	1388 DEG from cc2 dataset
# 0 DEG from hs1 dataset
#	193 DEG from hs2 dataset 
#	8 DEG from mm1 dataset
#	1071 DEG from mm2 dataset


##  DEG analysis. ##
## volcanoplots ##
# First of all, Volcanoplots of DEGs to compare foldchange vs pvalue were performed:
# EnhancedVolcano R package was used:
library(EnhancedVolcano)
# cc1 and cc2
# first of all, differentially expressed (padj<0.05) had to be sepparated
cc1_DEG<-cc1_finalData[cc1_finalData$padj<=0.05,] #selection of significally differentiated genes
cc1_DEG<-cc1_DEG[!is.na(cc1_DEG$SYMBOL),] # remove those thta do not have a gene identified
cc2_DEG<-cc2_finalData[cc2_finalData$padj<=0.05,]
cc2_DEG<-cc2_DEG[!is.na(cc2_DEG$SYMBOL),]

EnhancedVolcano(cc1_finalData, x = "log2FoldChange", y = "padj", lab = cc1_finalData$SYMBOL, pCutoff = 1e-4,FCcutoff = 1)
EnhancedVolcano(cc2_finalData, x = "log2FoldChange", y = "padj", lab = cc2_finalData$SYMBOL, pCutoff = 1e-4,FCcutoff = 1)
# hs2
hs2_DEG<-hs2_finalData[hs2_finalData$padj<=0.05,]
hs2_DEG<-hs2_DEG[!is.na(hs2_DEG$SYMBOL),]
EnhancedVolcano(hs2_finalData, x = "log2FoldChange", y = "padj", lab = hs2_finalData$SYMBOL, pCutoff = 0.05,FCcutoff = 1)
# mm2
mm2_DEG<-mm2_finalData[mm2_finalData$padj<=0.05,]
mm2_DEG<-mm2_DEG[!is.na(mm2_DEG$SYMBOL),]
mm2_genenames<-c(toupper(mm2_DEG$SYMBOL)) # for posterior analysis and comparisons, mice gene names need to be uppercase
EnhancedVolcano(mm2_finalData, x = "log2FoldChange", y = "padj", lab = mm2_finalData$SYMBOL, pCutoff = 1e-4,FCcutoff = 1)

## IEGs ##
# from DEGs I perform a list of IEGs 
IEGs <- c("FOS", "JUN", "EGR-1", "FOSB", "JUNB", "NR4A1", "ZENK",
          "ARC", "ATF3", "C-MYC", "EGR2", "FRA-1", "FRA-2", "JUND", 
          "MYC", "NPAS4", "PKG-1", "PKG-2","EGR3", "EGR4", "FOSL1", "FOSL2")
# then I search those terms in DEGs lists
table(IEGs %in% cc1_genenames)
table(IEGs %in% cc2_genenames)
# and extracted them and the gene information
df_IEGs_CC1 <- subset(cc1_DEG, SYMBOL %in% IEGs)
df_IEGs_CC1<-df_IEGs_CC1[,c(2,6,10)]
write.csv(df_IEGs_CC1,file = "./images/IEGs_cc1.cvs")

df_IEGs_CC2 <- subset(cc2_DEG, SYMBOL %in% IEGs)
df_IEGs_CC2<-df_IEGs_CC2[,c(2,6,10)]
write.csv(df_IEGs_CC2,file = "./images/IEGs_cc2.cvs")


## Dispersion plots ##
# After volcanoplots, log2foldchange of different datasets were compared by ploting and simple linear regression was performed to analyze the correlation
# to make the comparison, gene information of both datsets had to be ordered and for the same genes:
# cc1 and cc2
cc2DEG_cc1<-merge.data.frame(cc2_DEG,cc1_finalData,by = "ENTREZID") #by gene name, gene information is merged in only 1 dataframe
modcc2_cc1 <- lm(cc2DEG_cc1$log2FoldChange.x~cc2DEG_cc1$log2FoldChange.y, data = cc2DEG_cc1) # simple model using the log2foldchange to obtain the linear regression
plot(cc2DEG_cc1$log2FoldChange.x,cc2DEG_cc1$log2FoldChange.y,main = "cc2 vs cc1 DEG", xlab = "Log2FoldChange of cc2 DEG", ylab = "Log2FoldChange of cc1") # plotting of both log2foldchange for the genes diff expressed
abline(modcc2_cc1) # include the linear regression
modsum <- summary(modcc2_cc1) # here we can obtain the r^2 value of the linear regression
mylabel = bquote(italic(R)^2 == .(format(0.135))) 
text(x = 6.9, y = 5, labels = mylabel)# add the value of r^2

# hs2 vs cc1
hs2DEG_cc1<-merge.data.frame(hs2_DEG,cc1_finalData,by = "ENTREZID")
plot(hs2DEG_cc1$log2FoldChange.x,hs2DEG_cc1$log2FoldChange.y,main = "hs2 vs cc1 DEG", xlab = "Log2FoldChange of hs2 DEG", ylab = "Log2FoldChange of cc1 DEG")

# hs2 vs cc2
hs2DEG_cc2<-merge.data.frame(hs2_DEG,cc2_finalData,by = "ENTREZID")
plot(hs2DEG_cc2$log2FoldChange.x,hs2DEG_cc2$log2FoldChange.y,main = "hs2 vs cc2 DEG", xlab = "Log2FoldChange of hs2 DEG", ylab = "Log2FoldChange of cc2 DEG")


# mm2 vs cc1
mm2_DEG$SYMBOL<-toupper(mm2_DEG$SYMBOL)
mm2DEG_cc1<-merge.data.frame(mm2_DEG,cc1_finalData,by = "SYMBOL")
plot(mm2DEG_cc1$log2FoldChange.x,mm2DEG_cc1$log2FoldChange.y,main = "mm2 vs cc1 DEG", xlab = "Log2FoldChange of mm2 DEG", ylab = "Log2FoldChange of cc1 DEG")
modmm2_cc1 <- lm(mm2DEG_cc1$log2FoldChange.y~mm2DEG_cc1$log2FoldChange.x, data = mm2DEG_cc1)
abline(modmm2_cc1)
mylabel = bquote(italic(R)^2 == .(format(0.003)))
text(x = 7.5, y = 3, labels = mylabel)

# mm2 vs hs2
mm2DEG_hs2<-merge.data.frame(mm2_DEG,hs2_finalData,by = "SYMBOL")
plot(mm2DEG_hs2$log2FoldChange.x,mm2DEG_hs2$log2FoldChange.y,main = "mm2 vs hs2 DEG", xlab = "Log2FoldChange of mm2 DEG", ylab = "Log2FoldChange of hs2 DEG")
modmm2_hs2 <- lm(mm2DEG_hs2$log2FoldChange.y~mm2DEG_hs2$log2FoldChange.x, data = mm2DEG_hs2)
summary(modmm2_hs2)
abline(modmm2_hs2)
mylabel = bquote(italic(R)^2 == .(format(0.010)))
text(x = 8, y = 2, labels = mylabel)


## Venn Diagramas ## 
# To know how many genes are differentally expressed in differents datasets, Ven diaagrams were performed
# Diagrams were performed using the VennDiagram package
library(VennDiagram)
# cc1 vs cc2
venn.diagram(
  x = list(cc1_genenames, cc2_genenames),
  category.names = c("" , ""),
  col = "green",
  fill = c("#8fce00", "#f1c232"),
  cex = 2,
  main = "Neuronal cultures",
  filename = './images/cc1_cc2 diagramm.png',
  output=TRUE
)

# hs2 vs cc1 vs cc2
venn.diagram(
  x = list(cc1_genenames, cc2_genenames, hs2_genenames),
  category.names = c("" , "", ""),
  col = "green",
  fill = c("#8fce00", "#f1c232","#32bef1"),
  cex = 2,
  main = "Human samples vs Neuronal cultures",
  filename = './images/hs2_cc1_cc2 diagramm.png',
  output=TRUE
)

# cc1 vs hs2 vs mm2
venn.diagram(
  x = list(cc1_genenames, mm2_genenames,hs2_genenames),
  category.names = c("" , "",""),
  col = "green",
  fill = c("#8fce00", "#bf5813","#32bef1"),
  cex = 2,
  main = "",
  filename = './images/cc1_mm2_hs2 diagramm.png',
  output=TRUE
)


## Information about shared DEGs ##
common_hs2_cc1 <- intersect(cc1_genenames, hs2_genenames) # get the genes that are shared in DEGs lists
common_hs2_cc2 <- intersect(cc2_genenames, hs2_genenames)
common_hs2_cc1_cc2 <- intersect(common_hs2_cc2,common_hs2_cc1)

comon_hs2cc1cc2 <- subset(hs2_DEG, SYMBOL %in% common_hs2_cc1_cc2) # obtain gene information
comon_hs2cc1cc2<-comon_hs2cc1cc2[,c(2,5,9)]
write.csv(comon_hs2cc1cc2,file = "./images/comunes.cvs")

comon_cc1hscc2 <- subset(cc1_DEG, SYMBOL %in% common_hs2_cc1_cc2)
comon_cc1hscc2<-comon_cc1hscc2[,c(2,6,10)]
write.csv(comon_cc1hscc2,file = "./images/comunescc1.cvs")

comon_cc2cc1hs2 <- subset(cc2_DEG, SYMBOL %in% common_hs2_cc1_cc2)
comon_cc2cc1hs2<-comon_cc2cc1hs2[,c(2,6,10)]
write.csv(comon_cc2cc1hs2,file = "./images/comunescc2.cvs")

## Enrichment pathways analysis ##
# to perform this analysis I used  the clusterprofiler package

library(clusterProfiler)
library(org.Hs.eg.db)
library(AnnotationDbi)
library(org.Mm.eg.db)

# cc1
GO_results_cc1<-enrichGO(gene = cc1_genenames,OrgDb = "org.Hs.eg.db", keyType = "SYMBOL", ont = "MF") # for the function: the gene list to study, database with gene information, the type of gene name, and the tipe of function analyzed in this case is MF: molecular function
cc1_go_res<-as.data.frame(GO_results_cc1) # results in a table
fit_cc1<-plot(barplot(GO_results_cc1,showCategory = 10, font.size = 15))# ploting the results

# cc2
GO_results_cc2<-enrichGO(gene = cc2_genenames,OrgDb = "org.Hs.eg.db", keyType = "SYMBOL", ont = "MF")
cc2_go_res<-as.data.frame(GO_results_cc2)
fit<-plot(barplot(GO_results_cc2,showCategory = 20,  font.size = 15))

# cc1_cc2_common
GO_results_comon<-enrichGO(gene = common_cc1_cc2,OrgDb = "org.Hs.eg.db", keyType = "SYMBOL", ont = "MF")
cc1_cc2_common<-as.data.frame(GO_results_comon)
fit<-plot(barplot(GO_results_cccomon,showCategory = 10,font.size = 10))

# hs2
hs2_genenames<-c(hs2_DEG$SYMBOL)
GO_results_hs2<-enrichGO(gene = hs2_genenames,OrgDb = "org.Hs.eg.db", keyType = "SYMBOL", ont = "MF")
hs2_go_res<-as.data.frame(GO_results_hs2)
fihs2<-plot(barplot(GO_results_hs2,showCategory = 5))

# mm2
mm2_genenames<-c(mm2_DEG$SYMBOL)
GO_results_mm2<-enrichGO(gene = mm2_genenames,OrgDb = "org.Hs.eg.db", keyType = "SYMBOL", ont = "MF")
fit_mm2<-plot(barplot(GO_results_mm2,showCategory = 10, font.size = 15))
# mm2_cc1 common
GO_results_mm2_cc1<-enrichGO(gene = common_mm2_cc1,OrgDb = "org.Hs.eg.db", keyType = "SYMBOL", ont = "MF")
fit_mm2_cc1<-plot(barplot(GO_results_mm2_cc1,showCategory = 20, font.size = 15))
# mm2_hs2_common
GO_results_mm2_hs2<-enrichGO(gene = common_mm2_hs2,OrgDb = "org.Hs.eg.db", keyType = "SYMBOL", ont = "MF")
fit_mm2<-plot(barplot(GO_results_mm2_hs2,showCategory = 10)
# 3 common genes between cc1_hs2_mm2
GO_3genes<-enrichGO(gene = c("FAM167B","RAB29","LYNX1"),OrgDb = "org.Hs.eg.db", keyType = "SYMBOL", ont = "MF")
fit_mm2_cc1<-plot(barplot(GO_3genes,showCategory = 5))


