#!/bin/bash

# ==========================================================================================
# Setting vars
# ==========================================================================================

export PROJ_ID="lyra1_pool1"
export BASE_DIR="/projects/standard/modianoj/shared/walk1195/lyra_cfdna_pipeline" # scratch first, check size, move to main
export OUT_DIR="${BASE_DIR}/out/${PROJ_ID}"
export TMP_DIR="${BASE_DIR}/out/${PROJ_ID}/tmp"
export LOG_DIR="${OUT_DIR}/logs"

# Input data path
export INPUT_DATA_DIR="/projects/standard/modianoj/data_delivery/umgc/2026-q3/449568-20260819_0044/Modiano_Project_145_Pool_1"
export RAW_DIR="${BASE_DIR}/inputs/raw/${PROJ_ID}"

# Sample list
export SAMPLE_LIST="${BASE_DIR}/inputs/samples.txt"

# Input genome paths
export BWA_DIR="/projects/standard/modianoj/shared/walk1195/canfam4_Y_genome/bwa/canfam4_Y"
export REF="/projects/standard/modianoj/shared/RIS_Analysis/scRNA_sarcoma/Resources/CanFam4_Y/CanFam4_Y_genome/fasta/genome.fa"

# Output dirs
export FASTQ_DIR="${TMP_DIR}/fastqs"
export TRIM_DIR="${TMP_DIR}/fastqs_trimmed"
export FASTQC_DIR="${OUT_DIR}/fastqc"
export FASTQC_TRIM_DIR="${OUT_DIR}/fastqc_trimmed"
export BAM_DIR="${TMP_DIR}/bams"
export BAM_DEDUP_DIR="${BAM_DIR}/dedup"
export QC_DIR="${OUT_DIR}/bam_qc"

# Configure bin size
export BIN_SIZE="50kb"
export AUTOSOME_FILE="/projects/standard/modianoj/shared/walk1195/canfam4_Y_genome/canfam4_autosomes.genome"
export BIN_DIR="${TMP_DIR}/bins/${BIN_SIZE}"
export BINS_FILE="/inputs/canfam4_${BIN_SIZE}_bins.bed"


# If not a slurm job, set THREADS to 1
export THREADS=$([ ! -z ${SLURM_CPUS_PER_TASK+x} ] && echo ${SLURM_CPUS_PER_TASK} || echo 1)