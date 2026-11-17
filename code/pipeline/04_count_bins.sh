############################################################################################
# Genome bin counting
############################################################################################

# -------------------------------------------------------------------------------------------
# Count genome bin coverage
# -------------------------------------------------------------------------------------------
echo "Counting read coverage across bins...."

bedtools coverage \
        -a $BINS_FILE \
        -b ${BAM_DIR}dedup/${SAMPLE}_dedup.bam \
        -counts \
        > ${BIN_DIR}${SAMPLE}_counts.txt


# -------------------------------------------------------------------------------------------
# Process bin coverage counts
# -------------------------------------------------------------------------------------------
echo "Processing bin coverage...."

Rscript 04_process_bin_counts.R -s ${BIN_SIZE}

echo "Finished processing ${SAMPLE}. Results can be found at /scratch.global/walk1195/lyra/${PROJ_ID}/ "