#!/bin/bash

############################################################################################
# Run fastqc (PRE-TRIM)
############################################################################################
echo "Running fastqc...."

fastqc -t ${SLURM_CPUS_PER_TASK} --extract -o ${FASTQC_DIR} ${FASTQ_DIR}/${SAMPLE}.fastq

############################################################################################
# Run trimmomatic
############################################################################################
echo "Trimming read fragments...."

# have to specify exact path to .jar wrapper
java -jar /common/software/install/migrated/trimmomatic/0.33/trimmomatic-0.33.jar SE -threads ${SLURM_CPUS_PER_TASK} \
${FASTQ_DIR}/${SAMPLE}.fastq \
${TRIM_DIR}/${SAMPLE}_trimmed.fastq \
LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:35

############################################################################################
# Run fastqc (POST-TRIM)
############################################################################################
echo "Running fastqc...."

fastqc -t ${SLURM_CPUS_PER_TASK} --extract -o ${FASTQC_TRIM_DIR} ${TRIM_DIR}/${SAMPLE}_trimmed.fastq
