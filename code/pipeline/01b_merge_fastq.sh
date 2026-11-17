#!/bin/bash

############################################################################################
# Merge fastq files
############################################################################################

echo "Merging fastqs...."

cd ${OUT_DIR} 

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/fastqs/"

cat ${SAMPLE}-*-*.fastq > ${OUT_DIR}${SAMPLE}.fastq
