#############################################################################################
############################################################################################
### LyRA: Plotting genomic bin read coverage counts for plate 1 (Ultima)
### Samples: LyRA Ultima-Sequenced Plate 1 (n=93), see README.md
### Author: Grace Walker
### Date: July 23, 2026
#############################################################################################
#############################################################################################

# ------------------------------------------------------
# Env setup
# ------------------------------------------------------

# Load libs
library(tidyverse) # plotting / data manipulation
library(tibble) # data manip
library(RColorBrewer) # for colormaps
library(ComplexHeatmap) # for heatmaps
library(optparse) # for parsing slurm params
library(GenomicRanges)
library(Gviz)
library(karyoploteR)


# Params
options(future.globals.maxSize = 4 * 1024^3)  # Set to 4 GB
gc() # free up memory

# # Get bin size
# option_list = list(make_option(c("-s","--size"),
#                                type="character",
#                                default=NULL,
#                                help="Bin size. e.g. 500kb",metavar="character"))
#
# opt_parser = OptionParser(option_list=option_list);
# opt = parse_args(opt_parser);
# bin_size <- opt$size

# Set standard cols
cohort_cols <- c('Non-Lymphoid Malignancy' = '#462255FF', 'DLBCL' = '#FF8811FF', 'Control' = '#D44D5CFF')

# ------------------------------------------------------
# Set paths
# ------------------------------------------------------
projDir <- 'lyra_cfdna_pipeline'
dataDir <- '/projects/standard/modianoj/shared/walk1195/lyra/proj132/'

resDir <- paste0('proj132/Figures/',bin_size,'/')
countsDir <- paste0('proj132/bins/',bin_size,'/')

# ------------------------------------------------------
# Read in metadata
# ------------------------------------------------------
metadata <- read.table(file=glue::glue('{dataDir}Results/bin_counts/lyra_plate1_metadata_clean.tsv'), sep='\t', header=T)

################################################################################
# Read in bin coverage & normalize
################################################################################

counts_mat <- readRDS(file=glue::glue('{dataDir}Results/bin_counts/counts_mat_no_bcs.rds'))

# Normalize by cpm
cpm_mat = t(t(counts_mat) / colSums(counts_mat)) * 1e6 # add scaling factor
# Log-transform
log_mat = log2(cpm_mat + 1)
  
# Convert to bedGraph format (chr, start, end, value)
cov_centered <- cov_centered %>% 
  as.data.frame() %>%
  rownames_to_column('region') %>%
  separate(
    region,
    into = c("chr", "start", "end"),
    sep = ":",
    convert = TRUE)

# Mean-center
center_colmeans <- function(x) {
  xcenter = colMeans(x)
  x - rep(xcenter, rep.int(nrow(x), ncol(x)))}

cov_centered <- center_colmeans(log_mat)

# Fix chr col name
names(cov_centered)[names(cov_centered) == 'chr'] <- 'chromosome'

# Grab single sample for testing
#cov_single_sample <- cov_centered[,1:9] # 5 samples

### We may need to do some more data formatting, but will come back to it if needed



################################################################################
# Gviz - inspect individual gene / chromosome coverage
################################################################################

############## Build DataTrack objects ##############

# Plotting all 3 on top of each other
dTrack.1 <- DataTrack(range = cov_centered, genome = 'canFam4', chromosome = 'chr26', name='Coverage', col=cohort_cols)

plotTracks(d.Track1, col=cohort_cols, type='l', type='a', legend=T, chromosome = 'chr26',
           groups=metadata$cohort, aggregateGroups=T, aggregation='mean', start='38118261', end='38202372')


### Plotting individually

# Split IDs by cohort
cohort_samples <- split(rownames(metadata), metadata$cohort)

# Calculate average within each cohort
cov_control <- rowMeans(cov_centered[, cohort_samples$Control])
cov_dlbcl   <- rowMeans(cov_centered[, cohort_samples$DLBCL])
cov_malig     <- rowMeans(cov_centered[, cohort_samples$`Non-Lymphoid Malignancy`])

# Create GRanges objects
gr_control <- GRanges(seqnames = cov_centered$chr, ranges = IRanges(cov_centered$start, cov_centered$end), score = cov_control)
gr_dlbcl <- GRanges(seqnames = cov_centered$chr, ranges = IRanges(cov_centered$start, cov_centered$end), score = cov_dlbcl)
gr_malig <- GRanges(seqnames = cov_centered$chr, ranges = IRanges(cov_centered$start, cov_centered$end), score = cov_malig)

# Create a DataTrack obj per group
dTrack.control <- DataTrack(range = gr_control, genome = 'canFam4', chromosome = 'chr26', name='Control', col=cohort_cols, col="#D44D5CFF")
dTrack.dlbcl <- DataTrack(range = gr_dlbcl, genome = 'canFam4', chromosome = 'chr26', name='DLBCL', col="#FF8811FF")
dTrack.malig <- DataTrack(range = cov_centered, genome = 'canFam4', chromosome = 'chr26', name='Non-Lymphoid Malig.', col="#462255FF",
                          cex.title=1, cex.axis=.5)

gAxis <- GenomeAxisTrack(col = "grey")
plotTracks(list(gAxis, dTrack.dlbcl, dTrack.control, dTrack.malig), type='l', type='a', legend=T)


################################################################################
# karyoploteR - inspect coverage across entire genome
################################################################################


