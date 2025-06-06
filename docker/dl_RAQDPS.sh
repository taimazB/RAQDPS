#!/bin/bash
export dlLink="https://dd.weather.gc.ca/model_raqdps/10km/grib2"
export MAIN=$PWD

############################################################################

export lastHour=`echo ${lastAvailDateTime} | sed 's/.*T\(.*\)Z/\1/'`

# rm -r ${MAIN}/grib2 2>/dev/null ##  DO NOT REMOVE.  IF DL FAILS DUE TO LACK OF FILES, WANT TO CONTINUE LATER.
mkdir -p ${MAIN}/data/${MODEL}_grib2
cd ${MAIN}/data/${MODEL}_grib2

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

cd ${MAIN}
bash process_RAQDPS.sh ${lastAvailDateTime}
