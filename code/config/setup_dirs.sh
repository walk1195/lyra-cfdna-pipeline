#!/bin/bash

set -euo pipefail
source config/pipeline_config.sh

# ==========================================================================================
# Subdir setup
# ==========================================================================================

# Results directory structure:
#   ${BASE_DIR}/
#   ├── inputs/                            
#       ├── raw/                                (RAW_DIR)
#   └── out/
#       ├── ${PROJ_ID}/                         (PROJ_DIR)
#           ├── tmp/                            (TMP_DIR)
#           │   ├── fastqs/                     (FASTQ_DIR)
#           │   ├── fastqs_unmerged/            (FASTQ_UNMERGED_DIR)
#           │   ├── fastqs_trimmed/             (TRIM_DIR)
#           │   ├── bams/                       (BAM_DIR)
#           │       ├── dedup/                  (BAM_DEDUP_DIR)
#           └── results/                        (OUT_DIR)
#               ├── fastqc/                     (FASTQC_DIR)
#               ├── fastqc_trimmed/             (FASTQC_TRIM_DIR)
#               ├── bam_qc/                     (QC_DIR)
#               └── bins/${BIN_SIZE}/           (BIN_DIR)


ALL_DIRS=(
    "${OUT_DIR}"
    "${TMP_DIR}"
    "${RAW_DIR}"
    "${FASTQ_DIR}"
    "${TRIM_DIR}"
    "${BAM_DIR}"
    "${BAM_DEDUP_DIR}"
    "${FASTQC_DIR}"
    "${FASTQC_TRIM_DIR}"
    "${QC_DIR}"
    "${BIN_DIR}"
)

for dir in "${ALL_DIRS[@]}"; do
    if [ ! -d "${dir}" ]; then
        echo "Creating directory: ${dir}"
        mkdir -p "${dir}"
    fi
done

echo "All subdirs successfully created. Beginning sample processing...."
