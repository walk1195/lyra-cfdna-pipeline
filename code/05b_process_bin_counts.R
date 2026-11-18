#############################################################################################
############################################################################################
### LyRA: Processing of genomic bin read coverage counts for plate 1 (Ultima) -- FOR SLURM SCRIPT
### Samples: LyRA Ultima-Sequenced Plate 1 (n=93), see README.md
### Author: Grace Walker
### Date: July 09, 2026
#############################################################################################
#############################################################################################

# Load libs
library(tidyverse)
library(ggplot2)
library(vegan) # for PERMANOVA
library(RColorBrewer) # for colormaps
library(ComplexHeatmap) # for heatmaps
library(lme4) # for fitting mixed effect models
library(lmerTest) # for pvals
library(VennDiagram) # for inspecting breed overlaps
library(circlize) # for colormaps
library(optparse) # for parsing script params

# Params
options(future.globals.maxSize = 4 * 1024^3)  # Set to 4 GB
gc() # free up memory

# Get bin size
option_list = list(make_option(c("-s","--size"),
                               type="character",
                               default=NULL,
                               help="Bin size. e.g. 500kb",metavar="character"))

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);
bin_size <- opt$size

# ------------------------------------------------------
# Set paths
# ------------------------------------------------------
projDir <- 'proj132'
resDir <- paste0('proj132/Figures/',bin_size,'/')
countsDir <- paste0('proj132/bins/',bin_size,'/')

setwd('/projects/standard/modianoj/shared/walk1195/lyra')

# ------------------------------------------------------
# Read in metadata
# ------------------------------------------------------
metadata <- read.table(file='proj132/Results/bin_counts/lyra_plate1_metadata_clean.tsv', sep='\t', header=T)


################################################################################
# Merge bin counts across all samples
################################################################################
# Read in list of files
counts_files <- list.files(countsDir,pattern="_counts.txt")

counts_mat <- list()
for (sample_name in counts_files) {
  file_path <- paste0(countsDir,sample_name)
  # read in table
  counts_df <- read.table(file_path)
  # get bin counts vector
  counts_vector <- counts_df[,4]
  # get just sample id
  sample_id <- sub(paste0("_",bin_size,"_counts\\.txt$"), "", sample_name)
  # append to list
  counts_mat[[sample_id]] <- counts_vector
}

# Bind count vectors
counts_mat <- do.call(cbind, counts_mat)

# Ensure proper bin ID
bins <- read.table(paste0(countsDir,counts_files)[1])[,1:3]
bin_ids <- paste(bins$V1, bins$V2, bins$V3, sep=":")

# Update rownames
rownames(counts_mat) <- bin_ids

# Remove batch control samples
counts_mat <- counts_mat[, !grepl("bc_", colnames(counts_mat))] # now only 88 samples

# Save
print('Saving counts matrix...')
saveRDS(counts_mat, file = paste0("proj132/Results/bin_counts/counts_mat_",bin_size,"_no_bcs.rds"))

################################################################################
# Remove low count bins & normalize
################################################################################
# Checking for low count bins (mean count < 5–10)
# Mean count per bin
bin_means <- rowMeans(counts_mat)
any(bin_means < 100)
# Any samples that have a bin with less than 10 counts
colnames(counts_mat)[colSums(counts_mat < 10) > 0]

# Normalize by cpm
cpm_mat = t(t(counts_mat) / colSums(counts_mat)) * 1e6 # add scaling factor

# Log-transform
log_mat = log2(cpm_mat + 1)

# Transpose mat
log_mat_t <- t(log_mat)  # Samples should be rows now

# Remove bins with zero variance -- there are none
bin_var <- apply(log_mat_t, 2, var)
log_mat_t_filt <- log_mat_t[, bin_var > 0]

# Run PCA
print('Running PCA...')
pca_results <- prcomp(log_mat_t_filt)

# Extract PC scores
pca_df <- as.data.frame(pca_results$x)

# Merge metadata with pca results
pca_df <- cbind(pca_df, metadata)

################################################################################
# Plotting
################################################################################

# Set color maps
type_cols <-   c('plasma' = 'orange', 'serum' = 'steelblue1', 'streck' = 'mediumorchid')
  cohort_cols <- c('Non-Lymphoid Malignancy' = '#462255FF', 'DLBCL' = '#FF8811FF', 'Control' = '#D44D5CFF')
diagnosis_cols <- c('Healthy'= '#66C2A5', 'DLBCL' = '#FF8811FF', 'Soft Tissue Sarcoma' = '#8DA0CB', 'Osteosarcoma (oral)' = '#E78AC3' , 'Mast Cell Tumor' = '#FFD92F',
                    'Mammary Cancer' = '#A6D854', 'Unknown' = '#046E8FFF')
sex_colors <- c("M" = "lightblue", "F" = "darkmagenta", "Unknown" = "yellow")
read_depth_cols <- colorRamp2(c(min(metadata$read_depth), max(metadata$read_depth)), c("white", "darkblue"))
alignment_cols <- colorRamp2(c(min(metadata$alignment_rate)-10, max(metadata$alignment_rate)), c("white", "darkred"))

# Combine into color list
meta_colors <- list(
  type = type_cols,
  cohort = cohort_cols,
  diagnosis = diagnosis_cols,
  sex = sex_colors,
  read_depth = read_depth_cols,
  alignment_rate = alignment_cols)

#### PC plots
ggplot(pca_df, aes(x = PC1, y = PC2, color = cohort, shape = type)) +
  geom_point(size = 4, alpha = 0.8) +
  theme_minimal(base_size = 13) +
  scale_color_manual(values = cohort_cols) +
  scale_fill_manual(values = cohort_cols) +
  stat_ellipse(
    aes(fill = cohort, color = cohort, group = cohort),
    geom = "polygon",
    alpha = 0.2) +
  labs(title = "PCA by Genomic-Binned Read Counts",
       x = paste0("PC1 (", round(summary(pca_results)$importance[2,1]*100,1), "%)"),
       y = paste0("PC2 (", round(summary(pca_results)$importance[2,2]*100,1), "%)")) +
  theme(plot.title = element_text(face = "bold"))
ggsave(paste0(resDir,'pc1_pc2_by_disease_cohort_ultima_no_bcs.png'), width=8, height=6,dpi=400)

ggplot(pca_df, aes(x = PC3, y = PC4, color = cohort, shape = type)) +
  geom_point(size = 4, alpha = 0.8) +
  theme_minimal(base_size = 13) +
  scale_color_manual(values = cohort_cols) +
  scale_fill_manual(values = cohort_cols) +
  stat_ellipse(
    aes(fill = cohort, color = cohort, group = cohort),
    geom = "polygon",
    alpha = 0.2) +
  labs(title = "PCA by Genomic-Binned Read Counts",
       x = paste0("PC1 (", round(summary(pca_results)$importance[2,1]*100,1), "%)"),
       y = paste0("PC2 (", round(summary(pca_results)$importance[2,2]*100,1), "%)")) +
  theme(plot.title = element_text(face = "bold"))
ggsave(paste0(resDir,'pc3_pc4_by_disease_cohort_ultima_no_bcs.png'), width=8, height=6,dpi=400)


### Heatmaps
print('Plotting heatmaps....')

### Top 100
# Get top variable bins
vars <- apply(log_mat_t_filt, 2, var) # Calculate variance per bin
top_bins <- order(vars, decreasing = TRUE)[1:100] # Grab top 500

# Subset mat to top variable bins
heatmap_mat_subset <- log_mat_t_filt[, top_bins]
heatmap_mat_subset <- heatmap_mat_subset[rownames(pca_df),]

# Row-center 
heatmap_mat_centered <- sweep(heatmap_mat_subset, 2, colMeans(heatmap_mat_subset), "-")

# Set up col annotation
col_anno <- HeatmapAnnotation(read_depth = pca_df$read_depth, alignment_rate = pca_df$alignment_rate, sex = pca_df$sex, type = pca_df$type, cohort = pca_df$cohort, diagnosis = pca_df$diagnosis,
                              col = meta_colors,
                              annotation_legend_param = list(read_depth = list(at = c(20000000, 60000000, 100000000),
                                                                               labels = c("20 M", "60 M", "100 M"))))
# Plot
png(paste0(resDir, "heatmap_",bin_size,"_bins_row_centered_top100_no_bcs.png"), width = 3300, height = 3500, res = 400)
Heatmap(t(heatmap_mat_centered), # transpose for plotting
        top_annotation = col_anno,
        cluster_rows = TRUE,   # samples
        cluster_columns = TRUE, # bins
        show_row_names = FALSE,
        name='log2(cpm)',
        column_names_gp = grid::gpar(fontsize = 6))
dev.off()

### Top 500
# Get top variable bins
vars <- apply(log_mat_t_filt, 2, var) # Calculate variance per bin
top_bins <- order(vars, decreasing = TRUE)[1:500] # Grab top 500

# Subset mat to top variable bins
heatmap_mat_subset <- log_mat_t_filt[, top_bins]
heatmap_mat_subset <- heatmap_mat_subset[rownames(pca_df),]

# Row-center 
heatmap_mat_centered <- sweep(heatmap_mat_subset, 2, colMeans(heatmap_mat_subset), "-")

# Set up col annotation
col_anno <- HeatmapAnnotation(read_depth = pca_df$read_depth, alignment_rate = pca_df$alignment_rate, sex = pca_df$sex, type = pca_df$type, cohort = pca_df$cohort, diagnosis = pca_df$diagnosis,
                              col = meta_colors,
                              annotation_legend_param = list(read_depth = list(at = c(20000000, 60000000, 100000000),
                                                                               labels = c("20 M", "60 M", "100 M"))))
# Plot
png(paste0(resDir, "heatmap_",bin_size,"_bins_row_centered_top500_no_bcs.png"), width = 3300, height = 3500, res = 400)
Heatmap(t(heatmap_mat_centered), # transpose for plotting
        top_annotation = col_anno,
        cluster_rows = TRUE,   # samples
        cluster_columns = TRUE, # bins
        show_row_names = FALSE,
        name='log2(cpm)',
        column_names_gp = grid::gpar(fontsize = 6))
dev.off()

### Top 1000
# Get top variable bins
vars <- apply(log_mat_t_filt, 2, var) # Calculate variance per bin
top_bins <- order(vars, decreasing = TRUE)[1:1000] # Grab top 500

# Subset mat to top variable bins
heatmap_mat_subset <- log_mat_t_filt[, top_bins]
heatmap_mat_subset <- heatmap_mat_subset[rownames(pca_df),]

# Row-center 
heatmap_mat_centered <- sweep(heatmap_mat_subset, 2, colMeans(heatmap_mat_subset), "-")

# Set up col annotation
col_anno <- HeatmapAnnotation(read_depth = pca_df$read_depth, alignment_rate = pca_df$alignment_rate, sex = pca_df$sex, type = pca_df$type, cohort = pca_df$cohort, diagnosis = pca_df$diagnosis,
                              col = meta_colors,
                              annotation_legend_param = list(read_depth = list(at = c(20000000, 60000000, 100000000),
                                                                               labels = c("20 M", "60 M", "100 M"))))
# Plot
png(paste0(resDir, "heatmap_",bin_size,"_bins_row_centered_top1000_no_bcs.png"), width = 3300, height = 3500, res = 400)
Heatmap(t(heatmap_mat_centered), # transpose for plotting
        top_annotation = col_anno,
        cluster_rows = TRUE,   # samples
        cluster_columns = TRUE, # bins
        show_row_names = FALSE,
        name='log2(cpm)',
        column_names_gp = grid::gpar(fontsize = 6))
dev.off()

### Top 3000
# Get top variable bins
vars <- apply(log_mat_t_filt, 2, var) # Calculate variance per bin
top_bins <- order(vars, decreasing = TRUE)[1:3000] # Grab top 500

# Subset mat to top variable bins
heatmap_mat_subset <- log_mat_t_filt[, top_bins]
heatmap_mat_subset <- heatmap_mat_subset[rownames(pca_df),]

# Row-center 
heatmap_mat_centered <- sweep(heatmap_mat_subset, 2, colMeans(heatmap_mat_subset), "-")

# Set up col annotation
col_anno <- HeatmapAnnotation(read_depth = pca_df$read_depth, alignment_rate = pca_df$alignment_rate, sex = pca_df$sex, type = pca_df$type, cohort = pca_df$cohort, diagnosis = pca_df$diagnosis,
                              col = meta_colors,
                              annotation_legend_param = list(read_depth = list(at = c(20000000, 60000000, 100000000),
                                                                               labels = c("20 M", "60 M", "100 M"))))
# Plot
png(paste0(resDir, "heatmap_",bin_size,"_bins_row_centered_top3000_no_bcs.png"), width = 3300, height = 3500, res = 400)
Heatmap(t(heatmap_mat_centered), # transpose for plotting
        top_annotation = col_anno,
        cluster_rows = TRUE,   # samples
        cluster_columns = TRUE, # bins
        show_row_names = FALSE,
        name='log2(cpm)',
        column_names_gp = grid::gpar(fontsize = 6))
dev.off()

### Top 5000
# Get top variable bins
vars <- apply(log_mat_t_filt, 2, var) # Calculate variance per bin
top_bins <- order(vars, decreasing = TRUE)[1:5000] # Grab top 500

# Subset mat to top variable bins
heatmap_mat_subset <- log_mat_t_filt[, top_bins]
heatmap_mat_subset <- heatmap_mat_subset[rownames(pca_df),]

# Row-center 
heatmap_mat_centered <- sweep(heatmap_mat_subset, 2, colMeans(heatmap_mat_subset), "-")

# Set up col annotation
col_anno <- HeatmapAnnotation(read_depth = pca_df$read_depth, alignment_rate = pca_df$alignment_rate, sex = pca_df$sex, type = pca_df$type, cohort = pca_df$cohort, diagnosis = pca_df$diagnosis,
                              col = meta_colors,
                              annotation_legend_param = list(read_depth = list(at = c(20000000, 60000000, 100000000),
                                                                               labels = c("20 M", "60 M", "100 M"))))
# Plot
png(paste0(resDir, "heatmap_",bin_size,"_bins_row_centered_top5000_no_bcs.png"), width = 3300, height = 3500, res = 400)
Heatmap(t(heatmap_mat_centered), # transpose for plotting
        top_annotation = col_anno,
        cluster_rows = TRUE,   # samples
        cluster_columns = TRUE, # bins
        show_row_names = FALSE,
        name='log2(cpm)',
        column_names_gp = grid::gpar(fontsize = 6))
dev.off()


### Top 100 labelled
# Get top variable bins
vars <- apply(log_mat_t_filt, 2, var) # Calculate variance per bin
top_bins <- order(vars, decreasing = TRUE)[1:100] # Grab top 500

# Subset mat to top variable bins
heatmap_mat_subset <- log_mat_t_filt[, top_bins]
heatmap_mat_subset <- heatmap_mat_subset[rownames(pca_df),]

# Row-center 
heatmap_mat_centered <- sweep(heatmap_mat_subset, 2, colMeans(heatmap_mat_subset), "-")

# Set up col annotation
col_anno <- HeatmapAnnotation(read_depth = pca_df$read_depth, alignment_rate = pca_df$alignment_rate, sex = pca_df$sex, type = pca_df$type, cohort = pca_df$cohort, diagnosis = pca_df$diagnosis,
                              col = meta_colors,
                              annotation_legend_param = list(read_depth = list(at = c(20000000, 60000000, 100000000),
                                                                               labels = c("20 M", "60 M", "100 M"))))
# Plot
png(paste0(resDir, "heatmap_",bin_size,"_bins_top_100_row_centered_labelled.png"), width = 3500, height = 4000, res = 400)
Heatmap(t(heatmap_mat_centered), # transpose for plotting
        top_annotation = col_anno,
        cluster_rows = TRUE,   # samples
        cluster_columns = TRUE, # bins
        show_row_names = TRUE,
        row_names_side = 'right',
        row_names_gp = grid::gpar(fontsize = 6),
        name='log2(cpm)',
        col = colorRamp2(c(-2, 0, 2), c("blue", "white", "red")),
        column_names_gp = grid::gpar(fontsize = 6))
dev.off()

print(paste0('Post-processing finished. Script ran successfully; Results can be found at: ',resDir,bin_size))


