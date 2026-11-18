#!/bin/bash

############################################################################################
# Run bwa-mem
############################################################################################
echo "Aligning fastqs to reference genome...."

# Run bwa
bwa mem ${BWA_DIR} -t ${SLURM_CPUS_PER_TASK} -R "@RG\tID:sample1\tSM:sample1\tPL:ULTIMA" ${TRIM_DIR}/${SAMPLE}_trimmed.fastq > ${SAM_DIR}/${SAMPLE}.sam

# Convert sam file to unsorted bam
samtools view -Sb ${SAM_DIR}/${SAMPLE}.sam > ${SAM_DIR}/unsorted_${SAMPLE}.bam

# Sort bam files
samtools sort ${SAM_DIR}/unsorted_${SAMPLE}.bam -o ${BAM_DIR}/${SAMPLE}.bam
