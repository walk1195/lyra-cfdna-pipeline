#!/bin/bash -l

#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 8
#SBATCH --mem=8gb
#SBATCH --tmp=8gb
#SBATCH --time=12:00:00
#SBATCH --job-name=s3_download
#SBATCH --output=s3_download_%j.out
#SBATCH --error=s3_download_%j.err
#SBATCH --partition=msismall
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=walk1195@umn.edu

# Download S3 directory recursively
s3cmd get --recursive s3://modianoj-tier2/umgc/2025-q3/Modiano_Project_132/ /scratch.global/walk1195/lyra/