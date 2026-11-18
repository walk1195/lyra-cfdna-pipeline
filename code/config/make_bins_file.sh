#!/bin/bash

set -euo pipefail
source config/pipeline_config.sh

module load bedtools

# Configure bin size
export BIN_SIZE="50kb"
export BIN_DIR="${TMP_DIR}/bins/${BIN_SIZE}"
export BINS_FILE="/inputs/canfam4_${BIN_SIZE}_bins.bed"

# --- Configure bin size (options: 50kb, 500kb, 1Mb)
case "${BIN_SIZE,,}" in
    50kb)  export BIN_WIDTH=50000 ;;
    500kb) export BIN_WIDTH=500000 ;;
    1mb)   export BIN_WIDTH=1000000 ;;
    *)     echo "ERROR: unsupported BIN_SIZE '${BIN_SIZE}' (use 50kb, 500kb, or 1Mb)" >&2
           return 1 2>/dev/null || exit 1 ;;
esac

# --- Make  file
if [ ! -f "${BINS_FILE}" ]; then
    bedtools makewindows \
        -g "${AUTOSOME_FILE}" \
        -w "${BIN_WIDTH}" \
        > "${BINS_FILE}"
fi