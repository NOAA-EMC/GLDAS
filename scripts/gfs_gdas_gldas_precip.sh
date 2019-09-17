#!/bin/ksh
copygb=$COPYGB
finddate=finddate.sh
wgrib=$WGRIB
if [ $# -lt 1 ]; then
echo "usage: ksh $0 yyyymmdd [yyyymmdd2]"
exit
fi
yyyymmdd=$1
yyyymmdd2=$1
if [ $# -gt 1 ]; then
yyyymmdd2=$2
fi
echo $0 $yyyymmdd $yyyymmdd2

export LISDIR=/gpfs/dell2/emc/retros/noscrub/Youlong.Xia/gldas.v2.3.0/
export cpath=${DCOMROOT}/us007003
export fpath=/gpfs/dell2/ptmp/$USER/force
export xpath=/gpfs/dell2/ptmp/$USER/force

#--- extract variables of each timestep and create forcing files

set -A cc "00" "06" "12" "18"
#echo ${cc[0]}
#echo ${cc[1]}
#echo ${cc[2]}
#echo ${cc[3]}

while [ $yyyymmdd -le $yyyymmdd2 ];do

yyyymmdd0=`sh $finddate $yyyymmdd d-1`

mkdir -p $xpath/cpc.$yyyymmdd0
mkdir -p $xpath/cpc.$yyyymmdd

cd $xpath
rm -f fort.* grib.*

cpc=$cpath/$yyyymmdd/wgrbbul/cpc_rcdas/PRCP_CU_GAUGE_V1.0GLB_0.125deg.lnx.$yyyymmdd.RT
echo $cpc
if [ ! -s $cpc ]; then echo "$cpc not exist"; exit; fi
cp $cpc $xpath/cpc.$yyyymmdd/.

sflux=$fpath/gdas.${yyyymmdd0}/gdas1.t12z.sfluxgrbf06
prate=gdas.${yyyymmdd0}12
$wgrib -s $sflux | grep "PRATE:sfc" | $wgrib -i $sflux -grib -o $prate

sflux=$fpath/gdas.${yyyymmdd0}/gdas1.t18z.sfluxgrbf06
prate=gdas.${yyyymmdd0}18
$wgrib -s $sflux | grep "PRATE:sfc" | $wgrib -i $sflux -grib -o $prate

sflux=$fpath/gdas.${yyyymmdd}/gdas1.t00z.sfluxgrbf06
prate=gdas.${yyyymmdd}00
$wgrib -s $sflux | grep "PRATE:sfc" | $wgrib -i $sflux -grib -o $prate

sflux=$fpath/gdas.${yyyymmdd}/gdas1.t06z.sfluxgrbf06
prate=gdas.${yyyymmdd}06
$wgrib -s $sflux | grep "PRATE:sfc" | $wgrib -i $sflux -grib -o $prate

$copygb -i3 -g"255 0 2881 1441 90000 0 128 -90000 360000 125 125" -x gdas.${yyyymmdd0}12 grib.12
$copygb -i3 -g"255 0 2881 1441 90000 0 128 -90000 360000 125 125" -x gdas.${yyyymmdd0}18 grib.18
$copygb -i3 -g"255 0 2881 1441 90000 0 128 -90000 360000 125 125" -x gdas.${yyyymmdd}00  grib.00
$copygb -i3 -g"255 0 2881 1441 90000 0 128 -90000 360000 125 125" -x gdas.${yyyymmdd}06  grib.06

rm -f fort.10
touch fort.10
echo ${yyyymmdd0} >> fort.10
echo ${yyyymmdd}  >> fort.10

$wgrib -d -bin grib.12 -o fort.11
$wgrib -d -bin grib.18 -o fort.12
$wgrib -d -bin grib.00 -o fort.13
$wgrib -d -bin grib.06 -o fort.14

cp $xpath/cpc.$yyyymmdd/PRCP_CU_GAUGE_V1.0GLB_0.125deg.lnx.$yyyymmdd.RT fort.15

$LISDIR/exec/gfs_gdas_gldas_precip

cp fort.21 $xpath/cpc.$yyyymmdd0/precip.gldas.${yyyymmdd0}12
cp fort.22 $xpath/cpc.$yyyymmdd0/precip.gldas.${yyyymmdd0}18
cp fort.23 $xpath/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}00
cp fort.24 $xpath/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}06

rm -f fort.* grib.*

yyyymmdd=`sh $finddate $yyyymmdd d+1`
done
 
echo $fpath
echo $xpath
date
