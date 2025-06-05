##  This file is included in the docker image for reference only.

#!/bin/bash
export dlLink="https://dd.weather.gc.ca/model_raqdps/10km/grib2"
export MAIN=$PWD

############################################################################

# source ./configs.sh

lasts=()
for hr in 00 06 12 18; do
    last=`curl -s ${dlLink}/${hr}/072/ | grep grib2 | sed 's/.*"\(2.*\.grib2\)".*/\1/' | tail -1 | cut -d_ -f1`
    lasts+=(${last})
done

export lastAvailDateTime=`printf '%s\n' "${lasts[@]}"|sort | tail -1`
lastDlDateTime=`cat ${MAIN}/.lastDlDateTime`

if [[ -e ${MAIN}/.active ]] || [[ ${lastAvailDateTime} == ${lastDlDateTime} ]] || [[ -z ${lastAvailDateTime} ]] ; then
    exit
fi

touch ${MAIN}/.active
# rm -r ${MAIN}/nc 2>/dev/null

export lastHour=`echo ${lastAvailDateTime} | sed 's/.*T\(.*\)Z/\1/'`

# rm -r ${MAIN}/grib2 2>/dev/null ##  DO NOT REMOVE.  IF DL FAILS DUE TO LACK OF FILES, WANT TO CONTINUE LATER.
mkdir ${MAIN}/grib2
cd ${MAIN}/grib2

vars=(https://dd.weather.gc.ca/model_raqdps/10km/grib2/00/072/)

export var
for var in ${vars[@]}; do
    parallel 'wget -nc ${dlLink}/${lastHour}/{}/${lastAvailDateTime}_MSC_RAQDPS_PM2.5-WildfireSmokePlume_Sfc_RLatLon0.09_PT{}H.grib2' ::: {001..072}
done

##  Only proceed if data is available for all 48 forecast hours
N=${#vars[@]}
for h in {001..072}; do
    n=$(ls ${lastAvailDateTime}*${h}H.grib2 | wc -l)
    if [[ $n -lt $N ]]; then
	rm ${MAIN}/.active
	echo "##  Not enough $h: $n<$N"
	exit 1
    fi
done

echo ${lastAvailDateTime} > ${MAIN}/.lastDlDateTime

cd ${MAIN}
sbatch submit.sh
