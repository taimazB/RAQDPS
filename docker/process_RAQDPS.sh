date
# source ./configs.sh
export MAIN=$PWD
export MODEL=RAQDPS

##  FIND LATEST MODEL RUN
lastAvailDateTime=$1

export GRIB2_DIR=${MAIN}/data/${MODEL}_grib2
export NC_DIR=${MAIN}/data/${MODEL}_nc

############################################################################
##  FUNCTIONS

function rename {
    f=$1
    varOrgIn=$2 ## eg t2
    varNew=$3   ## eg airTemperature
    remapType=$4

    date=$(date -d $(cdo -s showtimestamp $f) +%Y%m%d_%H)
    out=${MODEL}_${varNew}_${date}

    mkdir -p ${NC_DIR}/${varNew} 2>/dev/null

    cdo -f nc4 copy -${remapType},${MAIN}/scripts/grid.txt -chname,${varOrgIn},${varNew} $f ${NC_DIR}/${varNew}/${out}.nc.1
    cdo -z zip_1 -chname,lat,latitude -chname,lon,longitude ${NC_DIR}/${varNew}/${out}.nc.1 ${NC_DIR}/${varNew}/${out}.nc
    rm ${NC_DIR}/${varNew}/${out}.nc.* 2>/dev/null
}
export -f rename

function mergeTime {
    var=$1
    cdo mergetime ${NC_DIR}/${var}/*.nc ${NC_DIR}/merged/${MODEL}_${var}.nc.1
    cdo -z zip_1 -intntime,12 HRDPS_airTemperature.nc.1 ${NC_DIR}/merged/${MODEL}_${var}.nc
    rm ${NC_DIR}/merged/${MODEL}_${var}.nc.1 2>/dev/null
}
export -f mergeTime

function removeDims {
    f=$1
    ncwa -O -a time,height ${f} ${f}.1
    mv ${f}.1 ${f}
    rm ${f}.* 2>/dev/null
}
export -f removeDims

function merge {
    speedFile=$1
    directionFile=$(echo $speedFile | sed "s/_windSpeed_/_windDirection_/")
    windFile=$(echo $speedFile | sed "s/_windSpeed_/_wind_/")

    cdo merge ${NC_DIR}/windSpeed/${speedFile} ${NC_DIR}/windDirection/${directionFile} ${NC_DIR}/wind/${windFile}
}
export -f merge


##  FUNCTIONS
############################################################################

##  GRIB2 -> NC
rm -r ${NC_DIR} 2>/dev/null
mkdir ${NC_DIR}
cd ${GRIB2_DIR}

##  RENAME FILES FOR TILE GENERATION
ls *${lastDlDateTime}*PM2.5-WildfireSmokePlume_Sfc*.grib2 | sort | parallel 'rename {} mdens PM25SFC remapbil' # PM2.5 surface concentration

##  kg/m3 -> ug/m3
cd ${NC_DIR}/PM25SFC
ls *_PM25SFC_*.nc | parallel 'ncap2 -O -s "PM25SFC*=10^9" {} {}'

##  REMOVE UNWANTED DIMENSIONS
cd ${NC_DIR}
find . -name *.nc | parallel 'removeDims {}'

cd ${MAIN}
python3 scripts/cnv.py ${MODEL} PM25SFC


date
