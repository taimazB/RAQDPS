#!/bin/bash
#SBATCH --job-name=RAWDPS
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --time=12:00:00
#SBATCH --output=logs/%j.out
#SBATCH --error=logs/%j.err
#SBATCH --priority=2001

##  This file is included in the docker image for reference only.

export MAIN=$PWD
export SERVER_DIR=/home/taimaz/Projects/Blender/Projects/sialuk

docker run --rm -v ./:/app raqdps:latest

rsync -ar --exclude '*.nc' ${MAIN}/nc ${SERVER_DIR}
rm -r ${MAIN}/grib2

rm .active
