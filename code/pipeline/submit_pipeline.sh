#!/bin/bash

# --- Prepare logs dir
echo "Clearing old logs in ${LOG_DIR}..."
rm -f "${LOG_DIR:?}"/*

# --- Config 
source config/pipeline_config.sh


# --- Dir setup 
bash config/setup_dirs.sh


# --- Make bins file
bash config/make_bins_file.sh


# --- Create symlinks
ln -sf "${INPUT_DATA_DIR}"/*.cram "${RAW_DIR}"/


# --- Generate sample list
find "${INPUT_DATA_DIR}" -maxdepth 1 -name "*.cram" -printf '%f\n' \
    | sed -E 's/^449568-//; s/-Z[0-9]+-[ACGT]+\.cram$//' \
    | sort > "${SAMPLE_LIST}"

N=$(wc -l < "${SAMPLE_LIST}")
if [ "${N}" -eq 0 ]; then
    echo "ERROR: no samples found in ${INPUT_DATA_DIR}" >&2
    exit 1
fi


####### Submit job array #######
echo "Submitting cfDNA analysis pipeline as SLURM job array (${N} samples)..."

# Call per-sample pipeline
ARRAY_JOB_ID=$(sbatch --parsable \
    --array=1-"${N}"%10 \
    --output="${LOG_DIR}/%x_%A_%a.out" \
    --error="${LOG_DIR}/%x_%A_%a.err" \
    run_pipeline.sh)
ARRAY_JOB_ID="${ARRAY_JOB_ID%%;*}"   # strips a ";cluster" suffix on multi-cluster setups

echo "Submitted array job ${ARRAY_JOB_ID}; summary will run after it finishes."

# Call summary script
sbatch \
    --dependency=afterok:"${ARRAY_JOB_ID}" \
    --kill-on-invalid-dep=yes \
    --job-name=lyra1_summary \
    --output="${LOG_DIR}/%x_%j.out" \
    --error="${LOG_DIR}/%x_%j.err" \
    run_summary.sh