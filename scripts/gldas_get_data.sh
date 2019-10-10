#!/bin/ksh
#
#########################################################
# This script generate gldas forcing from gdas prod sflux
#
# usage - gldas_get_data.sh yyyymmdd [yyyymmdd2]
# 
# script history:
# 20190509 Jesse Meng - first version
# 20191008 Youlong Xia - modified
#########################################################
force=1
finddate=finddate.sh
cnvgrib=$CNVGRIB
wgrib=$WGRIB
wgrib2=$WGRIB2
copygb=$COPYGB
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

### rpath = prod gdas sflux grib2
### fpath = gldas forcing grib2
### gpath = gldas forcing grib1

rpath=$COMROOT/gfs/prod
##rpath=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/v16rt0
fpath=/gpfs/dell2/ptmp/$USER
gpath=/gpfs/dell2/ptmp/$USER/force

#--- extract variables of each timestep and create forcing files
if [ $force -eq 1 ]; then
set -A cc "00" "06" "12" "18"
echo ${cc[0]}
#echo ${cc[1]}
#echo ${cc[2]}
#echo ${cc[3]}

while [ $yyyymmdd -le $yyyymmdd2 ];do
echo $fpath/gdas.$yyyymmdd
rm -fr $fpath/gdas.$yyyymmdd
mkdir -p $fpath/gdas.$yyyymmdd
echo $gpath/gdas.$yyyymmdd
rm -fr $gpath/gdas.$yyyymmdd
mkdir -p $gpath/gdas.$yyyymmdd

k=0
while [ $k -le 3 ]; do

# to get surface nemsio and tile netcdf files
cp $rpath/gfs.$yyyymmdd/${cc[k]}/gfs.t${cc[$k]}z.sfcanl.nemsio $gpath/gdas.$yyyymmdd
cp $rpath/gdas.$yyyymmdd/${cc[k]}/gdas.t${cc[$k]}z.sfcanl.nemsio $gpath/gdas.$yyyymmdd

cp $rpath/gfs.$yyyymmdd/${cc[k]}/RESTART/$yyyymmdd.${cc[$k]}0000.sfcanl_data.tile*.nc $gpath/gdas.$yyyymmdd

f=0
while [ $f -le 6 ]; do

rflux=$rpath/gdas.$yyyymmdd/${cc[$k]}/gdas.t${cc[$k]}z.sfluxgrbf00$f.grib2
fflux=$fpath/gdas.$yyyymmdd/gdas.t${cc[$k]}z.sfluxgrbf0$f.grib2
gflux=$gpath/gdas.$yyyymmdd/gdas1.t${cc[$k]}z.sfluxgrbf0$f
rm -f $fflux
touch $fflux
rm -f $gflux
touch $gflux
echo $rflux 
echo $fflux
echo $gflux

$wgrib2 $rflux | grep "TMP:1"     | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SPFH:1"    | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "DSWRF:s"   | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "DLWRF:s"   | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "UGRD:1"    | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "VGRD:1"    | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "PRES:s"    | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "PRATE:s"   | grep ave  | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "VEG:s"     | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "ALBDO:s"   | grep ave  | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "HGT:1"     | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SFCR:s"    | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SFEXC:s"   | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "TMP:s"     | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "WEASD:s"   | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SNOD:s"    | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SOILW:0-0" | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SOILW:0.1" | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SOILW:0.4" | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
$wgrib2 $rflux | grep "SOILW:1-2" | grep fcst | $wgrib2 -i $rflux -append -grib $fflux
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

yyyymmdd=`sh $finddate $yyyymmdd d+1`
done
fi

mkdir -p $gpath/gdas.$yyyymmdd
cp $rpath/gfs.$yyyymmdd/${cc[0]}/gfs.t00z.sfcanl.nemsio $gpath/gdas.$yyyymmdd
cp $rpath/gdas.$yyyymmdd/${cc[0]}/gdas.t00z.sfcanl.nemsio $gpath/gdas.$yyyymmdd
cp $rpath/gdas.$yyyymmdd/${cc[0]}/RESTART/$yyyymmdd.${cc[00]}0000.sfcanl_data.tile*.nc $gpath/gdas.$yyyymmdd

echo $rpath
echo $fpath
echo $gpath
