#!/bin/ksh
#
#########################################################
# This script generate gldas forcing from gdas prod sflux
#
# usage - gldas_get_data.sh sdate [edate]
# 
# script history:
# 20190509 Jesse Meng - first version
# 20191008 Youlong Xia - modified
#########################################################
set -x

cd $DATA

force=1
finddate=finddate.sh
cnvgrib=$CNVGRIB
wgrib=$WGRIB
wgrib2=$WGRIB2
copygb=$COPYGB

if [ $# -lt 1 ]; then 
echo "usage: ksh $0 start-date [end-date]"
err_exit 99
fi

sdate=$1
edate=$1
if [ $# -gt 1 ]; then
edate=$2
fi

### COMINgdas = prod gdas sflux grib2
### DATA = gldas forcing grib2
### DATA/force = gldas forcing grib1

fpath=$DATA
gpath=$DATA/force

mkdir -p $fpath
mkdir -p $gpath

#--- extract variables of each timestep and create forcing files
if [ $force -eq 1 ]; then
set -A cc "00" "06" "12" "18"
echo ${cc[0]}
#echo ${cc[1]}
#echo ${cc[2]}
#echo ${cc[3]}
fi

while [ $sdate -le $edate ];do

mkdir -p $fpath/gdas.${sdate}
mkdir -p $gpath/gdas.${sdate} 

k=0
while [ $k -le 3 ]; do

# to get surface 6-tile restart netcdf files

cp ${COMINgdas}/gdas.${sdate}/${cc[k]}/RESTART/${sdate}.${cc[$k]}0000.sfcanl_data.tile*.nc $gpath/gdas.${sdate}

f=0
while [ $f -le 6 ]; do

rflux=${COMINgdas}/gdas.$sdate/${cc[$k]}/gdas.t${cc[$k]}z.sfluxgrbf00$f.grib2
fflux=$fpath/gdas.${sdate}/gdas.t${cc[$k]}z.sfluxgrbf0$f.grib2
gflux=$gpath/gdas.${sdate}/gdas1.t${cc[$k]}z.sfluxgrbf0$f
rm -f $fflux
touch $fflux
rm -f $gflux
touch $gflux

fcsty=anl
if [ $f -ge 1 ]; then
fcsty=fcst
fi

$wgrib2 $rflux | grep "TMP:1"     | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SPFH:1"    | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "DSWRF:s"   | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "DLWRF:s"   | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "UGRD:1"    | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "VGRD:1"    | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "PRES:s"    | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "PRATE:s"   | grep ave  | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "VEG:s"     | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "ALBDO:s"   | grep ave  | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "HGT:1"     | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SFCR:s"    | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SFEXC:s"   | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "TMP:s"     | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "WEASD:s"   | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SNOD:s"    | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SOILW:0-0" | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SOILW:0.1" | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SOILW:0.4" | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SOILW:1-2" | grep $fcsty | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "LHTFL:s"   | grep ave  | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SHTFL:s"   | grep ave  | $wgrib2 -i $rflux -append -grib $fflux

#gds='255 4 3072 1536 89909 0 128 -89909 -117 117 768 0 0 0 0 0 0 0 0 0 255 0 0 0 0 0'
#$copygb -g"$gds" -x $fflux flux1534
#mv flux1534 $fflux

$cnvgrib -g21 $fflux $gflux 

(( f=$f+1 ))
done

(( k=$k+1 ))
done

sdate=`finddate.sh $sdate d+1`
done

mkdir -p $gpath/gdas.$sdate
cp ${COMINgdas}/gdas.$sdate/${cc[0]}/RESTART/$sdate.${cc[00]}0000.sfcanl_data.tile*.nc $gpath/gdas.$sdate


