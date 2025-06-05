date
# source ./configs.sh
export MAIN=$PWD
export MODEL=RAQDPS

##  FIND LATEST MODEL RUN
lastDlDateTime=$(cat ${MAIN}/.lastDlDateTime)

############################################################################
##  FUNCTIONS

function rename {
    f=$1
    varOrgIn=$2 ## eg t2
    varNew=$3   ## eg airTemperature
    remapType=$4

    date=$(date -d $(cdo -s showtimestamp $f) +%Y%m%d_%H)
    out=${MODEL}_${varNew}_${date}

    mkdir -p ${MAIN}/nc/${varNew} 2>/dev/null

    cdo -f nc4 copy -${remapType},${MAIN}/scripts/grid.txt -chname,${varOrgIn},${varNew} $f ${MAIN}/nc/${varNew}/${out}.nc.1
    cdo -z zip_1 -chname,lat,latitude -chname,lon,longitude ${MAIN}/nc/${varNew}/${out}.nc.1 ${MAIN}/nc/${varNew}/${out}.nc
    rm ${MAIN}/nc/${varNew}/${out}.nc.* 2>/dev/null
}
export -f rename

function mergeTime {
    var=$1
    cdo mergetime ${MAIN}/nc/${var}/*.nc ${MAIN}/nc/merged/${MODEL}_${var}.nc.1
    cdo -z zip_1 -intntime,12 HRDPS_airTemperature.nc.1 ${MAIN}/nc/merged/${MODEL}_${var}.nc
    rm ${MAIN}/nc/merged/${MODEL}_${var}.nc.1 2>/dev/null
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

    cdo merge ${MAIN}/nc/windSpeed/${speedFile} ${MAIN}/nc/windDirection/${directionFile} ${MAIN}/nc/wind/${windFile}
}
export -f merge


##  FUNCTIONS
############################################################################

##  GRIB2 -> NC
rm -r ${MAIN}/nc 2>/dev/null
mkdir ${MAIN}/nc
cd ${MAIN}/grib2

##  RENAME FILES FOR TILE GENERATION
ls *${lastDlDateTime}*PM2.5-WildfireSmokePlume_Sfc*.grib2 | sort | parallel 'rename {} mdens PM25SFC remapbil' # PM2.5 surface concentration

##  kg/m3 -> ug/m3
cd ${MAIN}/nc/PM25SFC
ls *_PM25SFC_*.nc | parallel 'ncap2 -O -s "PM25SFC*=10^9" {} {}'

##  REMOVE UNWANTED DIMENSIONS
cd ${MAIN}/nc
find . -name *.nc | parallel 'removeDims {}'

cd ${MAIN}
parallel 'python3 scripts/cnv.py {}' ::: PM25SFC


date
