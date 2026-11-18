#!/bin/bash -l

#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64
#SBATCH --partition=msismall
#SBATCH --time=4:00:00
#SBATCH --mem=64g
#SBATCH --tmp=12g # 100g of tmp
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=walk1195@umn.edu
#SBATCH --account=modianoj


# -------------------------------------------------------------------------------------------
# (1) Summarize QC metrics
# -------------------------------------------------------------------------------------------
echo "Summarizing QC metrics...."

Rscript 05a_summarize_bam_qc.R -s ${BIN_SIZE}

echo "Finished processing ${SAMPLE}. Results can be found at /scratch.global/walk1195/lyra/${PROJ_ID}/ "

# -------------------------------------------------------------------------------------------
# (2) Process bin coverage counts
# -------------------------------------------------------------------------------------------
echo "Processing bin coverage...."

Rscript 05b_process_bin_counts.R -s ${BIN_SIZE}

# -------------------------------------------------------------------------------------------
# (3) Plot summary genome coverage
# -------------------------------------------------------------------------------------------
echo "Plotting genome coverage...."

Rscript 06_plot_genome_coverage.R -s ${BIN_SIZE}


echo "Finished processing ${PROJ_ID} samples. Results can be found at ${OUT_DIR}"