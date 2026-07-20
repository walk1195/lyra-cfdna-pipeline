#!/bin/bash

# --- Prepare logs dir
echo "Setting up logs directory..."

if [ -d "logs" ]; then
    rm -rf logs/*
else
    mkdir -p logs
fi

# --- Submit job array
echo "Submitting Ultima pipeline as SLURM job..."

sbatch -p msismall ultima_processing_pipeline_test.sh