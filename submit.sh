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
export SERVER=taimaz.ddns.net
export SERVER_DIR=/home/taimaz/Projects/Blender/Projects/sialuk/data/models/PM25SFC/

export LOCAL_UID=$(id -u)
export LOCAL_GID=$(id -g)

docker run --user ${LOCAL_UID}:${LOCAL_GID} --rm -v ./:/app raqdps:latest

cd ${MAIN}/nc
for d in *; do
    cd ${MAIN}/nc/${d}
    rm *.nc
    mv data/cities.json .
    mv images/* .
    rm -r data images
done
rsync -aru ${MAIN}/nc/ ${SERVER_IP}:${SERVER_DIR}/

rm -r ${MAIN}/grib2 ${MAIN}/nc

rm .active
