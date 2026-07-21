#!/bin/bash

# ==========================================================================================
# Set vars
# ==========================================================================================

export PROJ_ID="lyra_cfdna_pipeline"
export BASE_DIR="/scratch.global/walk1195/${PROJ_ID}"
export TMP="${BASE_DIR}/tmp"
export OUT_DIR="${BASE_DIR}/results/"

# Setting sample list
export SAMPLE_LIST="/${BASE_DIR}/inputs/samples.txt"


# Input data path
export CRAM_DIR="/common/surfs/modianoj/umgc/2025-q3/Modiano_Project_132/"

# Input genome paths
export GENOME_DIR="/projects/standard/modianoj/shared/walk1195/canfam4_Y_genome/bowtie2/canFam4_Y"
export REF="/home/modianoj/shared/RIS_Analysis/scRNA_sarcoma/Resources/CanFam4_Y/CanFam4_Y_genome/fasta/genome.fa"


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