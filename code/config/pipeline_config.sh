#!/bin/bash

# ==========================================================================================
# Set vars
# ==========================================================================================

export PROJ_ID="lyra_cfdna_pipeline"
export BASE_DIR="/scratch.global/walk1195/${PROJ_ID}"
export TMP="${BASE_DIR}/tmp"
export OUT_DIR="${BASE_DIR}/results/"

# Input data path
export INPUT_DATA_DIR="/projects/standard/modianoj/data_delivery/umgc/2026-q3/449568-20260819_0044/Modiano_Project_145_Pool_1"

# Setting sample list
export SAMPLE_LIST="/${BASE_DIR}/inputs/samples.txt"

# Input genome paths
export BWA_DIR="/projects/standard/modianoj/shared/walk1195/canfam4_Y_genome/bwa/canfam4_Y"
export REF="/projects/standard/modianoj/shared/RIS_Analysis/scRNA_sarcoma/Resources/CanFam4_Y/CanFam4_Y_genome/fasta/genome.fa"

# Configure picard
export PICARD="java -jar ${PICARD_DIR}/picard.jar"

export BIN_SIZE="50kb"
export BIN_DIR="${BASE_DIR}/bins/${BIN_SIZE}"
export BINS_FILE="${BIN_DIR}/canfam4_${BIN_SIZE}_bins.bed"


# Output dirs
export FASTQ_DIR="${TMP_DIR}/fastqs"
export TRIM_DIR="${TMP_DIR}/fastqs_trimmed"
export FASTQC_DIR="${OUT_DIR}/fastqc"
export FASTQC_TRIM_DIR="${OUT_DIR}/fastqc_trimmed"
export BAM_DIR="${TMP_DIR}/bams"
export QC_DIR="${OUT_DIR}/bam_qc"


################ TODO: REVIEW ################

PICARD="java -jar $PICARD_DIR/picard.jar"


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
