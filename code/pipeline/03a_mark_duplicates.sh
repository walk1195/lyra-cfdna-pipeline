
#!/bin/bash

############################################################################################
# Picard MarkDuplicates
############################################################################################
echo "Removing duplicates...."

mkdir ${BAM_DIR}dedup/

# Run picard
${PICARD} MarkDuplicates \
        I=${BAM_DIR}${SAMPLE}_trimmed.bam \
        O=${BAM_DIR}dedup/${SAMPLE}_dedup.bam \
        M=${BAM_DIR}dedup/${SAMPLE}_metrics.txt \
        ASSUME_SORT_ORDER=coordinate \
        REMOVE_DUPLICATES=true \
        CREATE_INDEX=true