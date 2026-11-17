#!/bin/bash

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
${SAMPLE}.fastq \
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
