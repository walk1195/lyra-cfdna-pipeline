#!/bin/bash -l

#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64
#SBATCH --job-name=lyra1_plate1_analysis
#SBATCH --partition=msismall
#SBATCH --time=24:00:00
#SBATCH --mem=64g
#SBATCH --tmp=32g
#SBATCH --output=slurm_%A_%a.out
#SBATCH --error=slurm_%A_%a.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=walk1195@umn.edu
#SBATCH --account=modianoj
#SBATCH --array=1-n%10 # 10 samples at once, where n = number of samples in dataset

'''
Analysis pipeline to process LyRA cfDNA WGS samples.

Pipeline takes in raw .cram files as input and outputs an 'out' directory containing subdirectories of results.

Required inputs to run:
    - Set vars (see below) to reflect current project
    - Generate samples.txt file in inputs folder
    - Update GENOME_DIR if necessary
    - Change name of output and error files

'''

# ==========================================================================================
# Set up bash env
# ==========================================================================================

# Load modules
module load samtools
module load bowtie2
module load trimmomatic
module load fastqc
module load picard
module load bedtools
module load R/4.4.0-openblas-rocky8

echo $(which bowtie2)
echo $(which samtools)
echo $(which fastqc)
echo $(which bedtools)
echo $(which R)

# Configure picard
export PICARD="java -jar ${PICARD_DIR}/picard.jar"

# If not a slurm job, set THREADS to 1
export THREADS=$([ ! -z ${SLURM_CPUS_PER_TASK+x} ] && echo ${SLURM_CPUS_PER_TASK} || echo 1)


# Set vars -- editable
PROJ_ID="proj132" # Current proj ID
SAMPLE_LIST="/projects/standard/modianoj/shared/walk1195/lyra/${PROJ_ID}/samples.txt" # .txt file listing samples to be processed (no file extension)
CRAM_DIR="/common/surfs/modianoj/umgc/2025-q3/Modiano_Project_132/"
TMP_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/tmp/"
GENOME_DIR="/projects/standard/modianoj/shared/walk1195/canfam4_Y_genome/bowtie2/canFam4_Y"
SCRIPT_DIR="/projects/standard/modianoj/shared/walk1195/lyra/Scripts"
REF="/home/modianoj/shared/RIS_Analysis/scRNA_sarcoma/Resources/CanFam4_Y/CanFam4_Y_genome/fasta/genome.fa"


# Bin coverage
BIN_SIZE="50kb"
BIN_DIR="/projects/standard/modianoj/shared/walk1195/lyra/${PROJ_ID}/bins/" # updating for 1mb bins
BINS_FILE="${BIN_DIR}canfam4_${BIN_SIZE}_bins.bed"
NEW_BIN_DIR="/projects/standard/modianoj/shared/walk1195/lyra/${PROJ_ID}/bins/${BIN_SIZE}/" # updating for 50kb bins


# Get curr sample
SAMPLE="$(sed "${SLURM_ARRAY_TASK_ID}q;d" ${SAMPLE_LIST})"
echo "Processing reads for ${PROJ_ID}, ${SAMPLE}...."


# ==========================================================================================
# Set up subdirs
# ==========================================================================================

# Create all subdirs
if [ ! -d "/scratch.global/walk1195/lyra/${PROJ_ID}" ]; then
    echo "Creating project dir and subdirs..."
    mkdir -p "/scratch.global/walk1195/lyra/${PROJ_ID}"
fi

# Create each subdirectory if missing
cd /scratch.global/walk1195/lyra/$PROJ_ID

SUB_DIRS=(fastqs fastqs_trimmed fastqc fastqc_trimmed bams featurecounts tmp)

for sub in "${SUB_DIRS[@]}"; do
    if [ ! -d "${sub}" ]; then
        echo "Creating subdirectory: ${sub}"
        mkdir -p "${sub}"
    fi
done

if [ ! -d "tmp/fastqs_unmerged" ]; then
    echo "Creating subdirectory: tmp/fastqs_unmerged"
    mkdir -p "tmp/fastqs_unmerged"
fi

echo "All subdirs successfully created. Beginning sample processing...."


############################################################################################
# Convert cram files to fastq
############################################################################################
echo "Converting cram files to fastq...."

# Set out dir and file
OUT_DIR="${TMP_DIR}fastqs_unmerged/"

# Convert and save to curr wkdir IF file doesn't already exist
for FILE in ${CRAM_DIR}${SAMPLE}*.cram; do

	echo "Converting "${SAMPLE}" ..."

    BASE_NAME=$(basename "${FILE}" .cram)
    OUT_FILE="${OUT_DIR}${BASE_NAME}.fastq"
    
	samtools fastq -0 "${OUT_FILE}" "${FILE}" # -0 indicates non-single/paired end read pattern
done

############################################################################################
# Merge fastq files
############################################################################################

echo "Merging fastqs...."

cd ${OUT_DIR} 

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/fastqs/"

cat ${SAMPLE}-*-*.fastq > ${OUT_DIR}${SAMPLE}-combined.fastq # could remove the combined tag later


############################################################################################
# Run fastqc (PRE-TRIM)
############################################################################################
echo "Running fastqc...."

cd /scratch.global/walk1195/lyra/${PROJ_ID}/fastqs/

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/fastqc/"

fastqc -t ${SLURM_CPUS_PER_TASK} --extract -o ${OUT_DIR} ${SAMPLE}.fastq

############################################################################################
# Run trimmomatic
############################################################################################
echo "Trimming read fragments...."

OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/fastqs/"
cd ${OUT_DIR}

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/fastqs_trimmed/"

# have to specify exact path to .jar wrapper
java -jar /common/software/install/migrated/trimmomatic/0.33/trimmomatic-0.33.jar SE -threads ${SLURM_CPUS_PER_TASK} \
${SAMPLE}-combined.fastq \
${OUT_DIR}${SAMPLE}_trimmed.fastq \
LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:35

############################################################################################
# Run fastqc (POST-TRIM)
############################################################################################
echo "Running fastqc...."

cd /scratch.global/walk1195/lyra/${PROJ_ID}/fastqs_trimmed/

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/fastqc_trimmed/"

fastqc -t ${SLURM_CPUS_PER_TASK} --extract -o ${OUT_DIR} ${SAMPLE}_trimmed.fastq


############################################################################################
# Run bowtie2 alignment *** currently no subfolder in tmp dir, could add it
############################################################################################
echo "Aligning fastqs to reference genome...."

# Set wkdir
cd /scratch.global/walk1195/lyra/${PROJ_ID}/fastqs_trimmed/

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/bams/"

# Run bowtie2
bowtie2 -p ${SLURM_CPUS_PER_TASK} -x ${GENOME_DIR} -U ${SAMPLE}_trimmed.fastq -S ${TMP_DIR}${SAMPLE}.sam

# Convert sam file to unsorted bam
samtools view -Sb ${TMP_DIR}${SAMPLE}.sam > ${TMP_DIR}unsorted_${SAMPLE}.bam

# Sort bam files
samtools sort ${TMP_DIR}unsorted_${SAMPLE}.bam -o ${OUT_DIR}${SAMPLE}.bam


############################################################################################
# Picard MarkDuplicates
############################################################################################
echo "Removing duplicates...."

mkdir ${BAM_DIR}dedup/

# Run picard
${PICARD} MarkDuplicates \
        I=${BAM_DIR}${SAMPLE}_trimmed.bam \
        O=${BAM_DIR}dedup/${SAMPLE}_dedup.bam \
        M=${BAM_DIR}dedup/${SAMPLE}_metrics.txt \
        ASSUME_SORT_ORDER=coordinate \
        REMOVE_DUPLICATES=true \
        CREATE_INDEX=true

############################################################################################
# Collect BAM quality metrics
############################################################################################

echo "Collecting BAM QC Metrics..."

mkdir ${OUT_DIR}qc/

OUT_DIR="${OUT_DIR}qc/"

# samtools flagstat -- summary of mapped vs unmapped
samtools flagstat -@ ${SLURM_CPUS_PER_TASK} ${BAM_DIR}${SAMPLE}_dedup.bam > ${OUT_DIR}${SAMPLE}_dedup_bam_qc_flagstat.txt

# samtools stats -- deeper per sample QC
samtools stats -@ ${SLURM_CPUS_PER_TASK} ${BAM_DIR}${SAMPLE}_dedup.bam > ${OUT_DIR}${SAMPLE}_dedup_bam_qc_stats.txt

# Picard CollectInsertSizeMetrics -- fragment distribution of reads
${PICARD} CollectInsertSizeMetrics -I ${BAM_DIR}${SAMPLE}_dedup.bam -O ${OUT_DIR}${SAMPLE}_dedup_bam_qc_insertsize_metrics.txt -H ${OUT_DIR}${SAMPLE}_dedup_bam_qc_insertsize_metrics_histogram.pdf

# Picard CollectAlignmentSummaryMetrics -- general alignment QC (mapping rate, mismatch rate, etc.)
${PICARD} CollectAlignmentSummaryMetrics -R ${REF} -I ${BAM_DIR}${SAMPLE}_dedup.bam -O ${OUT_DIR}${SAMPLE}_dedup_bam_qc_alignment_summary.txt

# Picard CollectGCBiasMetrics -- assessing GC bias
${PICARD} CollectGcBiasMetrics -I ${BAM_DIR}${SAMPLE}_dedup.bam -O ${OUT_DIR}${SAMPLE}_dedup_bam_qc_gcbias_metrics.txt -CHART ${OUT_DIR}${SAMPLE}_dedup_bam_qc_gcbias_chart.pdf -S ${OUT_DIR}${SAMPLE}_dedup_bam_qc_gcbias_summary.txt -R ${REF}


############################################################################################
# Genome bin counting
############################################################################################

# -------------------------------------------------------------------------------------------
# Count genome bin coverage
# -------------------------------------------------------------------------------------------
echo "Counting read coverage across bins...."

bedtools coverage \
        -a $BINS_FILE \
        -b ${BAM_DIR}dedup/${SAMPLE}_dedup.bam \
        -counts \
        > ${BIN_DIR}${SAMPLE}_counts.txt


# -------------------------------------------------------------------------------------------
# Process bin coverage counts
# -------------------------------------------------------------------------------------------
echo "Processing bin coverage...."

Rscript pipeline/process_bin_counts_batch.R -s ${BIN_SIZE}

echo "Finished processing ${SAMPLE}. Results can be found at /scratch.global/walk1195/lyra/${PROJ_ID}/ "




