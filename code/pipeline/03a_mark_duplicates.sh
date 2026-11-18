
#!/bin/bash

############################################################################################
# Picard MarkDuplicates
############################################################################################
echo "Removing duplicates...."

# Run picard
${PICARD} MarkDuplicates \
        I=${BAM_DIR}/${SAMPLE}_trimmed.bam \
        O=${BAM_DEDUP_DIR}/${SAMPLE}_dedup.bam \
        M=${BAM_DEDUP_DIR}/${SAMPLE}_metrics.txt \
        ASSUME_SORT_ORDER=coordinate \
        REMOVE_DUPLICATES=true \
        CREATE_INDEX=true