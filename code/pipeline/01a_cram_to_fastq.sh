#!/bin/bash

############################################################################################
# Convert cram to fastq
############################################################################################

echo "Converting "${SAMPLE}" to fastq..."

# Convert and save to curr wkdir IF file doesn't already exist
CRAM=$(find "${RAW_DIR}" -maxdepth 1 -name "449568-${SAMPLE}-Z[0-9]*.cram" | head -n 1)

# Stop if no cram found
[ -n "${CRAM}" ] || { echo "ERROR: no CRAM found for ${SAMPLE}" >&2; exit 1; }

OUT_FILE="${FASTQ_DIR}/${SAMPLE}.fastq"

samtools fastq -0 "${OUT_FILE}" "${CRAM}" # -0 indicates non-single/paired end read pattern

