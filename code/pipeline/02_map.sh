#!/bin/bash

############################################################################################
# Run bwa-mem
############################################################################################
echo "Aligning fastqs to reference genome...."

# Set wkdir
cd /scratch.global/walk1195/lyra/${PROJ_ID}/fastqs_trimmed/

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/bams/"

# Run bwa
bwa mem ${BWA_DIR} -t ${SLURM_CPUS_PER_TASK} -R "@RG\tID:sample1\tSM:sample1\tPL:ULTIMA" ${SAMPLE}_trimmed.fastq > ${TMP_DIR}${SAMPLE}.sam

# Convert sam file to unsorted bam
samtools view -Sb ${TMP_DIR}${SAMPLE}.sam > ${TMP_DIR}unsorted_${SAMPLE}.bam

# Sort bam files
samtools sort ${TMP_DIR}unsorted_${SAMPLE}.bam -o ${OUT_DIR}${SAMPLE}.bam
