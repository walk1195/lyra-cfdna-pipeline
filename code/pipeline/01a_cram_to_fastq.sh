#!/bin/bash

############################################################################################
# Convert cram files to fastq
############################################################################################

echo "Converting cram files to fastq...."

# Set out dir and file
OUT_DIR="${TMP_DIR}fastqs/"

# Convert and save to curr wkdir IF file doesn't already exist
for FILE in ${INPUT_DATA_DIR}${SAMPLE}*.cram; do

	echo "Converting "${SAMPLE}" ..."

    BASE_NAME=$(basename "${FILE}" .cram)
    OUT_FILE="${OUT_DIR}${BASE_NAME}.fastq"
    
	samtools fastq -0 "${OUT_FILE}" "${FILE}" # -0 indicates non-single/paired end read pattern
done