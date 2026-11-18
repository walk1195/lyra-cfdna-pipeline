#!/bin/bash -l

#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64
#SBATCH --job-name=lyra1_analysis
#SBATCH --partition=msismall
#SBATCH --time=24:00:00
#SBATCH --mem=64g
#SBATCH --tmp=100g # 100g of tmp
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=walk1195@umn.edu
#SBATCH --account=modianoj

'''
Analysis pipeline to process LyRA cfDNA WGS samples.

Pipeline takes in raw .cram files as input and outputs an 'out' directory containing subdirectories of results.

Required inputs to run:
    - Set vars (see below) to reflect current project
    - Generate samples.txt file in inputs folder
    - Update GENOME_DIR if necessary
    - Change name of output and error files

'''

set -euo pipefail

# ==========================================================================================
# Set up bash env
# ==========================================================================================

module load samtools
module load bwa
module load trimmomatic
module load fastqc
module load picard
module load bedtools
module load R/4.4.0-openblas-rocky8

echo $(which bwa)
echo $(which trimmomatic)
echo $(which samtools)
echo $(which fastqc)
echo $(which bedtools)
echo $(which R)

# Load config
source config/pipeline_config.sh

# If not a slurm job, set THREADS to 1
export THREADS=$([ ! -z ${SLURM_CPUS_PER_TASK+x} ] && echo ${SLURM_CPUS_PER_TASK} || echo 1)

# Get sample ID
export SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${SAMPLE_LIST}")
echo "Processing reads for ${PROJ_ID}, ${SAMPLE}...."


# ==========================================================================================
# Execute pipeline
# ==========================================================================================
echo "Processing ${SAMPLE}...."

bash pipeline/01a_cram_to_fastq.sh

#bash pipeline/01b_merge_fastq.sh # TODO: create if statement

bash pipeline/01c_trim_fastq.sh

bash pipeline/02_map.sh

bash pipeline/03a_mark_duplicates.sh

bash pipeline/03b_collect_qc_metrics.sh

bash pipeline/04_count_bins.sh

bash 05_plot_genome_coverage.R


echo "Finished processing ${SAMPLE}. Results can be found at ${OUT_DIR}"