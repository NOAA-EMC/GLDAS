#!/bin/ksh
#########################################################
# This script generate gldas forcing from gdas prod sflux
# script history:
# 20190509 Jesse Meng - first version
# 20191008 Youlong Xia - modified
# 20191123 Fanglin Yang - restructured for global-workflow
#########################################################

export VERBOSE=${VERBOSE:-"YES"}
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXECUTING $0 $* >&2
   set -x
fi


bdate=$1
edate=$2


### COMINgdas = prod gdas sflux grib2
### RUNDIR = gldas forcing in grib2 format
### RUNDIR/force = gldas forcing in grib1 format
fpath=$RUNDIR
gpath=$RUNDIR/force
cycint=${assim_freq:-6}

# get gdas flux files to force gldas.
# CPC precipitation is from 12z to 12z. One more day of gdas data is 
# needed to disaggregate daily CPC precipitation values to hourly values
cdate=`$NDATE -24 $bdate`

#-------------------------------
while [ $cdate -lt $edate ]; do
#-------------------------------
  ymd=`echo $cdate |cut -c 1-8`
  cyc=`echo $cdate |cut -c 9-10`
  [[ ! -d $fpath/gdas.${ymd} ]] && mkdir -p $fpath/gdas.${ymd}
  [[ ! -d $gpath/gdas.${ymd} ]] && mkdir -p $gpath/gdas.${ymd} 

f=1
while [ $f -le $cycint ]; do
  rflux=${COMINgdas}/gdas.$ymd/$cyc/gdas.t${cyc}z.sfluxgrbf00$f.grib2
  fflux=$fpath/gdas.$ymd/gdas.t${cyc}z.sfluxgrbf0$f.grib2
  gflux=$gpath/gdas.$ymd/gdas1.t${cyc}z.sfluxgrbf0$f
  rm -f $fflux $gflux
  touch $fflux $gflux

  fcsty=anl
  if [ $f -ge 1 ]; then fcsty=fcst; fi

  $WGRIB2 $rflux | grep "TMP:1 hybrid"     | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "SPFH:1 hybrid"    | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "UGRD:1 hybrid"    | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "VGRD:1 hybrid"    | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "HGT:1 hybrid"     | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "PRES:surface"     | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "PRATE:surface"    | grep ave  | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "VEG:surface"      | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "SFCR:surface"     | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "SFEXC:surface"    | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "TMP:surface"      | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "WEASD:surface"    | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "SNOD:surface"     | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "SOILW:0-0"        | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "SOILW:0.1"        | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "SOILW:0.4"        | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux
  $WGRIB2 $rflux | grep "SOILW:1-2"        | grep $fcsty | $WGRIB2 -i $rflux -append -grib $fflux

  if [ $f -lt 1 ]; then
    $WGRIB2 $rflux | grep "DSWRF:surface:anl"    | $WGRIB2 -i $rflux -append -grib $fflux
    $WGRIB2 $rflux | grep "DLWRF:surface:anl"    | $WGRIB2 -i $rflux -append -grib $fflux
    $WGRIB2 $rflux | grep "USWRF:surface:anl"    | $WGRIB2 -i $rflux -append -grib $fflux
  else
    $WGRIB2 $rflux | grep "DSWRF:surface:$f hour fcst"  | $WGRIB2 -i $rflux -append -grib $fflux
    $WGRIB2 $rflux | grep "DLWRF:surface:$f hour fcst"  | $WGRIB2 -i $rflux -append -grib $fflux
    $WGRIB2 $rflux | grep "USWRF:surface:$f hour fcst"  | $WGRIB2 -i $rflux -append -grib $fflux
  fi

  #gds='255 4 3072 1536 89909 0 128 -89909 -117 117 768 0 0 0 0 0 0 0 0 0 255 0 0 0 0 0'
  #$COPYGB -g"$gds" -x $fflux flux1534
  #mv flux1534 $fflux

  $CNVGRIB -g21 $fflux $gflux 
  f=$((f+1))
done



#-------------------------------
  cdate=`$NDATE +$cycint $cdate` 
done
#-------------------------------

exit 
