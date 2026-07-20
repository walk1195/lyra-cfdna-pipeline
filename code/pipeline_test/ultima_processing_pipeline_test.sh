#!/bin/bash -l

#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 64 # fastqc uses max amount of cores
#SBATCH --partition=msismall
#SBATCH --time=24:00:00
#SBATCH --mem=64g
#SBATCH --tmp=32g
#SBATCH --output=logs/process_ultima_%A_%a.out
#SBATCH --error=logs/process_ultima_%A_%a.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=walk1195@umn.edu
#SBATCH --account=modianoj
#SBATCH --array=1-5%5 # 5 samples at once # where n = number of samples in the dataset

# Clear logs from previous run
if [ -d "logs" ]; then
    rm -rf logs/*
    mkdir -p logs
else
    mkdir -p logs
fi

# Load modules
module load samtools
module load bowtie2
module load trimmomatic
module load fastqc
module load R/4.4.0-openblas-rocky8


# Set vars -- editable
PROJ_ID="ultima_pipeline_test" # Current proj ID
SAMPLE_LIST="/projects/standard/modianoj/shared/walk1195/lyra/${PROJ_ID}/samples.txt" # .txt file listing samples to be processed (no file extension)
CRAM_DIR="/common/surfs/modianoj/umgc/2025-q3/Modiano_Project_132/"
TMP_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/tmp/"
GENOME_DIR="/projects/standard/modianoj/shared/walk1195/canfam4_Y_genome/bowtie2/canFam4_Y"
SCRIPT_DIR="/projects/standard/modianoj/shared/walk1195/lyra/Scripts"

# Get curr sample
SAMPLE="$(sed "${SLURM_ARRAY_TASK_ID}q;d" ${SAMPLE_LIST})"
echo "Processing reads for ${PROJ_ID}, ${SAMPLE}...."


# Create all subdirs
if [ ! -d "/scratch.global/walk1195/lyra/${PROJ_ID}" ]; then
    echo "Creating project dir and subdirs..."
    mkdir -p "/scratch.global/walk1195/lyra/${PROJ_ID}"
fi

# Create each subdirectory if missing
cd /scratch.global/walk1195/lyra/$PROJ_ID

SUB_DIRS=(fastqs fastqs_trimmed fastqc bams featurecounts tmp)

for sub in "${SUB_DIRS[@]}"; do
    if [ ! -d "${sub}" ]; then
        echo "Creating subdirectory: ${sub}"
        mkdir -p "${sub}"
    fi
done

if [ ! -d "tmp/fastqs_unmerged" ]; then
    echo "Creating subdirectory: tmp/fastqs_unmerged"
    mkdir -p "tmp/fastqs_unmerged"
fi

echo "All subdirs successfully created. Beginning sample processing...."


###########################################################
# Convert cram files to fastq
###########################################################
echo "Converting cram files to fastq...."

# Set out dir and file
OUT_DIR="${TMP_DIR}fastqs_unmerged/"

# Convert and save to curr wkdir IF file doesn't already exist
for FILE in ${CRAM_DIR}${SAMPLE}*.cram; do

	echo "Converting "${SAMPLE}" ..."

    BASE_NAME=$(basename "${FILE}" .cram)
    OUT_FILE="${OUT_DIR}${BASE_NAME}.fastq"
    
	samtools fastq -0 "${OUT_FILE}" "${FILE}" # -0 indicates non-single/paired end read pattern
done

###########################################################
# Merge fastq files
###########################################################
echo "Merging fastqs...."

cd ${OUT_DIR} 

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/fastqs/"

cat ${SAMPLE}-*-*.fastq > ${OUT_DIR}${SAMPLE}-combined.fastq # could remove the combined tag later

###########################################################
# Run trimmomatic
###########################################################
echo "Trimming read fragments...."

cd ${OUT_DIR}

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/fastqs_trimmed/"

# have to specify exact path to .jar wrapper
java -jar /common/software/install/migrated/trimmomatic/0.33/trimmomatic-0.33.jar SE -threads 24 \
${SAMPLE}-combined.fastq \
${OUT_DIR}${SAMPLE}_trimmed.fastq \
LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:35

###########################################################
# Run fastqc
###########################################################
echo "Running fastqc...."

cd /scratch.global/walk1195/lyra/${PROJ_ID}/fastqs_trimmed/

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/fastqc/"

fastqc -t 64 --extract -o ${OUT_DIR} ${SAMPLE}_trimmed.fastq


###########################################################
# Run bowtie2 alignment *** currently no subfolder in tmp dir, could add it
###########################################################
echo "Aligning fastqs to reference genome...."

# Set wkdir
cd /scratch.global/walk1195/lyra/${PROJ_ID}/fastqs_trimmed/

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/bams/"

# Run bowtie2
bowtie2 -p 32 -x ${GENOME_DIR} -U ${SAMPLE}_trimmed.fastq -S ${TMP_DIR}${SAMPLE}.sam

# Convert sam file to unsorted bam
samtools view -Sb ${TMP_DIR}${SAMPLE}.sam > ${TMP_DIR}unsorted_${SAMPLE}.bam

# Sort bam files
samtools sort ${TMP_DIR}unsorted_${SAMPLE}.bam -o ${OUT_DIR}${SAMPLE}.bam


###########################################################
# Run featurecounts
###########################################################
echo "Running FeatureCounts...."

# cd back to dir where featurecounts R script lives
cd ${SCRIPT_DIR}

# Set new out dir
OUT_DIR="/scratch.global/walk1195/lyra/${PROJ_ID}/featurecounts/"

Rscript featurecounts_general.R -o ${OUT_DIR} -s ${SAMPLE} -p ${PROJ_ID}

echo "Finished processing ${SAMPLE}. Results can be found at /scratch.global/walk1195/lyra/${PROJ_ID}/ "





