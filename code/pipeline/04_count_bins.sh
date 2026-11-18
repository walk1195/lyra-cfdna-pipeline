#!/bin/bash

############################################################################################
# Count genome bin coverage
############################################################################################

echo "Counting read coverage across bins...."

bedtools coverage \
        -a ${BINS_FILE} \
        -b ${BAM_DEDUP_DIR}/${SAMPLE}_dedup.bam \
        -counts \
        > ${BIN_DIR}/${SAMPLE}_counts.txt