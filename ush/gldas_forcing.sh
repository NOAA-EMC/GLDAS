#!/bin/ksh
#
###########################################################################
# this script gets cpc daily precipitation and using gdas hourly precipitation
# to disaggregate daily value into hourly value
#  usage - gldas_forcing.sh sdate [edate]
#
# 20190509 Jesse Meng - first version
# 20191008 Youlong Xia - modified
########################################################################### 
set -x

copygb=$COPYGB
finddate=finddate.sh
wgrib=$WGRIB
if [ $# -lt 1 ]; then
echo "usage: ksh $0 sdate [edate]"
err_exit 99
fi
sdate=$1
edate=$1
if [ $# -gt 1 ]; then
edate=$2
fi

sda=${sdate}
export RUNDIR=${DATA}/gldas.${sdate}
cd $RUNDIR

# HOMEgldas - gldas directory
# EXECgldas - gldas exec directory
# PARMgldas - gldas param directory
# FIXgldas  - gldas fix field directory

export LISDIR=$HOMEgldas
export cpath=$DCOMIN
export fpath=${DATA}/force
export xpath=${DATA}/force

mkdir -p input
ln -s $fpath $RUNDIR/input/GDAS

#--- extract variables of each timestep and create forcing files

set -A cc "00" "06" "12" "18"

while [ $sdate -le $edate ];do

sdat0=`sh $finddate $sdate d-1`

mkdir -p $xpath/cpc.$sdat0
mkdir -p $xpath/cpc.$sdate

cd $xpath
rm -f fort.* grib.*

cpc=$cpath/$sdate/wgrbbul/cpc_rcdas/PRCP_CU_GAUGE_V1.0GLB_0.125deg.lnx.$sdate.RT

if [ ! -s $cpc ]; then echo "$cpc not exist"; exit; fi
cp $cpc $xpath/cpc.$sdate/

sflux=$fpath/gdas.${sdate}/gdas1.t12z.sfluxgrbf06
prate=gdas.${sdat0}12
$wgrib -s $sflux | grep "PRATE:sfc" | $wgrib -i $sflux -grib -o $prate

sflux=$fpath/gdas.${sdat0}/gdas1.t18z.sfluxgrbf06
prate=gdas.${sdat0}18
$wgrib -s $sflux | grep "PRATE:sfc" | $wgrib -i $sflux -grib -o $prate

sflux=$fpath/gdas.${sdate}/gdas1.t00z.sfluxgrbf06
prate=gdas.${sdate}00
$wgrib -s $sflux | grep "PRATE:sfc" | $wgrib -i $sflux -grib -o $prate

sflux=$fpath/gdas.${sdate}/gdas1.t06z.sfluxgrbf06
prate=gdas.${sdate}06
$wgrib -s $sflux | grep "PRATE:sfc" | $wgrib -i $sflux -grib -o $prate

$copygb -i3 -g"255 0 2881 1441 90000 0 128 -90000 360000 125 125" -x gdas.${sdat0}12 grib.12
$copygb -i3 -g"255 0 2881 1441 90000 0 128 -90000 360000 125 125" -x gdas.${sdat0}18 grib.18
$copygb -i3 -g"255 0 2881 1441 90000 0 128 -90000 360000 125 125" -x gdas.${sdate}00  grib.00
$copygb -i3 -g"255 0 2881 1441 90000 0 128 -90000 360000 125 125" -x gdas.${sdate}06  grib.06

rm -f fort.10
touch fort.10
echo ${sdat0} >> fort.10
echo ${sdate}  >> fort.10

$wgrib -d -bin grib.12 -o fort.11
$wgrib -d -bin grib.18 -o fort.12
$wgrib -d -bin grib.00 -o fort.13
$wgrib -d -bin grib.06 -o fort.14

cp $xpath/cpc.$sdate/PRCP_CU_GAUGE_V1.0GLB_0.125deg.lnx.${sdate}.RT fort.15

export pgm=gldas_forcing
  . prep_step

$EXECgldas/gldas_forcing >> $pgmout 2>>errfile
export err=$?; err_chk

cp fort.21 $xpath/cpc.$sdat0/precip.gldas.${sdat0}12
cp fort.22 $xpath/cpc.$sdat0/precip.gldas.${sdat0}18
cp fort.23 $xpath/cpc.$sdate/precip.gldas.${sdate}00
cp fort.24 $xpath/cpc.$sdate/precip.gldas.${sdate}06

rm -f fort.* grib.*

sdate=`sh $finddate $sdate d+1`

done

