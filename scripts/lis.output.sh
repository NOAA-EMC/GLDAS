#!/bin/ksh
#
#########################################################
# This script collects gldas output to archive directory
#
# usage - lis.output.sh BDATE [GDATE]
#         BDATE/GDATE in yyyymmdd
#
# LISDIR - software directory
# COMDIR - output archive directory
# RUNDIR - run directory
# GDAS   - /com/gfs/prod
#
# gldas runs 72 hrs, from day1.00z to day4.00z
# first 36 hr obs precip forcing
# second 36 hrs gdas model forcing to bring it to realtime.
#
# save all output to day1 directory
# save noah.rst.day2 to day2 directory for next day restart
# save gdas.t00z.sfcanl.nemsio.gldas.day4 to day4 directory for gfs restart
#
# script history:
# 20190604 Jesse Meng - first version
#########################################################
set -ux
export FINDDATE=finddate.sh

if [ $# -lt 1 ]; then
echo "usage: ksh $0 yyyymmdd [yyyymmdd2]"
exit
fi
BDATE=$1
yyyymmdd1=$1
yyyymmdd2=`sh $FINDDATE $1 d+1`
if [ $# -gt 1 ]; then yyyymmdd2=$2 ; fi
GDATE=$yyyymmdd2

yyyy=`echo $yyyymmdd1 | cut -c1-4`

### define work directories

export LISDIR=/gpfs/dell2/emc/retros/noscrub/Youlong.Xia/gldas.v2.3.0
export COMDIR=/gpfs/dell2/emc/retros/noscrub/$USER/gldas.T1534.igbp.2019/output
export RUNDIR=/gpfs/dell2/ptmp/$USER/gldas.$BDATE
export GDAS=$COMROOThps/gfs/prod

### setup archive directories
### save all output to day1 directory

mkdir -p $COMDIR/gldas.$yyyymmdd1
yyyymmdd=`sh $FINDDATE $yyyymmdd1 d+1`
while [ $yyyymmdd -le $yyyymmdd2 ]; do

mkdir -p $COMDIR/gldas.$yyyymmdd

yyyy=`echo $yyyymmdd | cut -c1-4`
cp $RUNDIR/EXP901/NOAH/$yyyy/$yyyymmdd/* $COMDIR/gldas.$yyyymmdd1

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`
done

### rename grb files

yyyymmdd=$yyyymmdd1
while [ $yyyymmdd -lt $yyyymmdd2 ]; do

day1=$yyyymmdd
day2=`sh $FINDDATE $yyyymmdd d+1`
mv $COMDIR/gldas.$yyyymmdd1/LIS.E901.${day2}00.NOAH.grb $COMDIR/gldas.$yyyymmdd1/LIS.E901.${day1}00.NOAH.grb

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`
done

### save noah.rst.day2 to day2 directory for next day gldas restart 

yyyymmdd=`sh $FINDDATE $yyyymmdd1 d+1`
yyyy=`echo $yyyymmdd | cut -c1-4`
mkdir -p $COMDIR/gldas.$yyyymmdd
cp $RUNDIR/EXP901/NOAH/$yyyy/$yyyymmdd/LIS.E901.${yyyymmdd}00.Noahrst $COMDIR/gldas.$yyyymmdd/noah.rst.$yyyymmdd

### generate and save gdas.t00z.sfcanl.nemsio.gldas.day4 to day4 directory for next cycle gfs restart

mkdir -p $COMDIR/gldas.$yyyymmdd2
yyyy=`echo $yyyymmdd2 | cut -c1-4`
gbin=$RUNDIR/EXP901/NOAH/$yyyy/$yyyymmdd2/LIS.E901.${yyyymmdd2}00.NOAHgbin
cp $GDAS/gdas.$yyyymmdd2/gfs.t00z.sfcanl.nemsio $COMDIR/gldas.$yyyymmdd2
cp $GDAS/gdas.$yyyymmdd2/gdas.t00z.sfcanl.nemsio $COMDIR/gldas.$yyyymmdd2
sfcanl=$COMDIR/gldas.$yyyymmdd2/gdas.t00z.sfcanl.nemsio
$LISDIR/scripts/gfs_gdas_gldas_gldas2gdas.sh $gbin $sfcanl
mv $sfcanl.gldas $sfcanl.gldas.$yyyymmdd2


echo $COMDIR/gldas.$yyyymmdd1
echo $COMDIR/gldas.$yyyymmdd/noah.rst.$yyyymmdd
echo $COMDIR/gldas.$yyyymmdd2/gdas.t00z.sfcanl.nemsio.gldas.$yyyymmdd2
