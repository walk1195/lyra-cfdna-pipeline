#!/bin/bash

############################################################################################
# Collect BAM quality metrics
############################################################################################

echo "Collecting BAM QC Metrics..."

mkdir ${OUT_DIR}qc/

OUT_DIR="${OUT_DIR}qc/"

# samtools flagstat -- summary of mapped vs unmapped
samtools flagstat -@ ${SLURM_CPUS_PER_TASK} ${BAM_DIR}${SAMPLE}_dedup.bam > ${OUT_DIR}${SAMPLE}_dedup_bam_qc_flagstat.txt

# samtools stats -- deeper per sample QC
samtools stats -@ ${SLURM_CPUS_PER_TASK} ${BAM_DIR}${SAMPLE}_dedup.bam > ${OUT_DIR}${SAMPLE}_dedup_bam_qc_stats.txt

# Picard CollectInsertSizeMetrics -- fragment distribution of reads
${PICARD} CollectInsertSizeMetrics -I ${BAM_DIR}${SAMPLE}_dedup.bam -O ${OUT_DIR}${SAMPLE}_dedup_bam_qc_insertsize_metrics.txt -H ${OUT_DIR}${SAMPLE}_dedup_bam_qc_insertsize_metrics_histogram.pdf

# Picard CollectAlignmentSummaryMetrics -- general alignment QC (mapping rate, mismatch rate, etc.)
${PICARD} CollectAlignmentSummaryMetrics -R ${REF} -I ${BAM_DIR}${SAMPLE}_dedup.bam -O ${OUT_DIR}${SAMPLE}_dedup_bam_qc_alignment_summary.txt

# Picard CollectGCBiasMetrics -- assessing GC bias
${PICARD} CollectGcBiasMetrics -I ${BAM_DIR}${SAMPLE}_dedup.bam -O ${OUT_DIR}${SAMPLE}_dedup_bam_qc_gcbias_metrics.txt -CHART ${OUT_DIR}${SAMPLE}_dedup_bam_qc_gcbias_chart.pdf -S ${OUT_DIR}${SAMPLE}_dedup_bam_qc_gcbias_summary.txt -R ${REF}

