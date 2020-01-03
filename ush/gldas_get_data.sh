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
USHgldas=$3

touch ./cfile

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

##  echo "${USHgldas}/gldas_process_data.sh $rflux $fcsty $fflux $gflux $f" >> ./cfile
  ${USHgldas}/gldas_process_data.sh $rflux $fcsty $fflux $gflux $f

  f=$((f+1))
done

#-------------------------------
  cdate=`$NDATE +$cycint $cdate` 
done
#-------------------------------

##mpirun cfp ./cfile

exit 
