#!/bin/ksh
#
#########################################################
# This script runs gldas from BDATE 00Z to GDATE 00Z 
#
# usage - lis.run.sh BDATE [GDATE]
#         BDATE/GDATE in yyyymmdd 
#
# LISDIR - software directory
# COMDIR - output archive directory
# RUNDIR - run directory 
# GDAS   - forcing directory
#
# script history:
# 20190509 Jesse Meng - first version
# 20191008 Youlong Xia - modified
#########################################################
set -ux
export COPYGB=${COPYGB:-$COPYGB}
export FINDDATE=${FINDDATE:-finddate.sh}

if [ $# -lt 1 ]; then
echo "usage: ksh $0 yyyymmdd [yyyymmdd2]"
exit
fi
BDATE=$1
yyyymmdd0=`sh $FINDDATE $1 d-1`
yyyymmdd1=$1
yyyymmdd2=`sh $FINDDATE $1 d+1`
if [ $# -gt 1 ]; then yyyymmdd2=$2 ; fi
yyyy=`echo $yyyymmdd1 | cut -c1-4`

echo "GLDAS runs from $yyyymmdd1 00Z to $yyyymmdd2 00Z"

### define work directories

export LISDIR=/gpfs/dell2/emc/retros/noscrub/Youlong.Xia/GLDAS
export COMDIR=/gpfs/dell2/emc/retros/noscrub/$USER/gldas.T1534.igbp.2019/output
export RUNDIR=/gpfs/dell2/ptmp/$USER/gldas.$BDATE
export GDAS=/gpfs/dell2/ptmp/$USER/force

### setup RUNDIR and model

export model=noah
export cyc0=00
export input1=/gpfs/dell2/ptmp/Youlong.Xia/force/${dir1}/gldas.${yyyymmdd0}/ 

rm -fr $RUNDIR
mkdir -p $RUNDIR
cd $RUNDIR
ln -s $LISDIR/fix/FIX_T1534 $RUNDIR/FIX
ln -s $LISDIR/exec/gldas_${model} $RUNDIR/LIS

### get forcing data, nemsio file, and tile netcdf file

yyyymmdd=$yyyymmdd0
while [ $yyyymmdd -lt $yyyymmdd2 ];do

$LISDIR/scripts/gldas_get_data.sh $yyyymmdd

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`
done

### produce gldas frocing when daily cpc precipitation is used

yyyymmdd=$yyyymmdd1
while [ $yyyymmdd -lt $yyyymmdd2 ];do

$LISDIR/scripts/gldas_forcing.sh $yyyymmdd

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`
done

yyyymmdd=$yyyymmdd1
while [ $yyyymmdd -lt $yyyymmdd2 ];do

gds='255 4 3072 1536 89909 0 128 -89909 -117 117 768 0 0 0 0 0 0 0 0 0 255 0 0 0 0 0'
$COPYGB -i3 -g"$gds" -x $GDAS/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}00 $RUNDIR/cmap.gdas.${yyyymmdd}00
$COPYGB -i3 -g"$gds" -x $GDAS/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}06 $RUNDIR/cmap.gdas.${yyyymmdd}06
$COPYGB -i3 -g"$gds" -x $GDAS/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}12 $RUNDIR/cmap.gdas.${yyyymmdd}12
$COPYGB -i3 -g"$gds" -x $GDAS/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}18 $RUNDIR/cmap.gdas.${yyyymmdd}18

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`
 
done

cd $RUNDIR
mkdir -p input
ln -s $GDAS $RUNDIR/input/GDAS

### create restart file
   echo "create noah.rst from 6-tile nc files in gdas.$yyyymmdd1/RESTART/"
   cp ${LISDIR}/parm/gdas2gldas.input fort.41
   sed -i -e 's/date/'"$yyyymmdd0"'/g' -e 's/cyc/'"$cyc0"'/g' fort.41 
   sed -i 's|/indirect/|'"$input1"'|g' fort.41   
   $LISDIR/scripts/run.gdas2gldas_${model}.dell.sh $BDATE  

   sfcanl=$RUNDIR/sfc.gaussian.nemsio
   if [ ! -s $sfcanl ]; then echo "$sfcanl produced from gdas2gldas CANNOT FIND; STOP!"; exit; fi
   rm -f fort.11 fort.12
   ln -s $LISDIR/fix/FIX_T1534/lmask_gfs_T1534.bfsa fort.11
   ln -s $sfcanl fort.12
   $LISDIR/exec/gldas_${model}_rst
   cp noah.rst noah.rst.$yyyymmdd1
fi

### create configure file

$LISDIR/scripts/gldas_liscrd.sh $yyyymmdd1 $yyyymmdd2 1534

### create lsf file

cp $LISDIR/parm/LIS.lsf.tmp LIS.lsf
echo "#BSUB -oo $RUNDIR/LIS.out"   >> LIS.lsf
echo "#BSUB -eo $RUNDIR/LIS.error" >> LIS.lsf
echo "cd $RUNDIR"                  >> LIS.lsf
echo "mpirun -n 112 ./LIS"            >> LIS.lsf
echo "$LISDIR/scripts/gldas_archive.sh $yyyymmdd1 $yyyymmdd2" >> LIS.lsf

### run

bsub<$RUNDIR/LIS.lsf

echo $RUNDIR
