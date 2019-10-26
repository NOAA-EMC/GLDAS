#!/bin/ksh
#
#########################################################
# This script runs gldas from BDATE 00Z to GDATE 00Z 
#
# usage - gldas_driver.sh GDATE
#         GDATE in yyyymmdd 
#
# HOMEgldas - software directory
# COMDIR    - output archive directory
# WORKDIR   - run directory 
# GDAS   - forcing directory
#
# script history:
# 20190509 Jesse Meng - first version
# 20191008 Youlong Xia - modified
#########################################################
set -x

export FINDDATE=${FINDDATE:-finddate.sh}

mkdir $RUNDIR
cd $RUNDIR

if [ $# -lt 1 ]; then
  echo "Usage: gldas_driver.sh RUNENDDATE [RUNENDDATE]"
  err_exit 99
fi

RUNSTARTDATE=$1
yyyymmdd0=`sh $FINDDATE $1 d-1`
RUNENDDATE=`sh $FINDDATE $1 d+1`

if [ $# -gt 1 ]; then RUNENDDATE=$2 ; fi
yyyy=`echo $RUNSTARTDATE | cut -c1-4`

QUEUE="debug"
PROJECT_CODE="NLDAS-T2O"

echo $RUNSTARTDATE
echo "USING: $RUNSTARTDATE to GET START DATA"
echo "RUNNING THROUGH: $RUNENDDATE"

echo "GLDAS runs from $yyyymmdd0 00Z to $yyyymmdd2 00Z"

# As CPC precipitation is from 12z to 12z, the script needs to get one more
# day gdas data to disaggregate daily CPC precipitation value to hourly

### define soft irectories

export GDAS=${DATA}/force
mkdir -p $GDAS

export input1=$GDAS/gdas.$RUNSTARTDATE
export input2=$GDAS/gdas.$RUNENDDATE

cd $RUNDIR

ln -s $FIXgldas/FIX_T1534 $RUNDIR/FIX
ln -s $EXECgldas/gldas_${model} $RUNDIR/LIS


### 1) Get all gdas data and 6-tile netcdf restart data -----

yyyymmdd=$yyyymmdd0
while [ $yyyymmdd -lt $RUNENDDATE ];do

$HOMEgldas/ush/gldas_get_data.sh $yyyymmdd

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`
done

### 2) Get CPC daily precip and temporally disaggreated ---

yyyymmdd=$RUNSTARTDATE
while [ $yyyymmdd -lt $RUNENDDATE ];do

$HOMEgldas/ush/gldas_forcing.sh $yyyymmdd

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`
done

mkdir -p input
ln -s $GDAS $RUNDIR/input/GDAS

### spatially disaggregated
yyyymmdd=$RUNSTARTDATE

while [ $yyyymmdd -lt $RUNENDDATE ]; do

gds='255 4 3072 1536 89909 0 128 -89909 -117 117 768 0 0 0 0 0 0 0 0 0 255 0 0 0 0 0'

$COPYGB -i3 -g"$gds" -x $GDAS/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}00 $RUNDIR/cmap.gdas.${yyyymmdd}00
$COPYGB -i3 -g"$gds" -x $GDAS/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}06 $RUNDIR/cmap.gdas.${yyyymmdd}06
$COPYGB -i3 -g"$gds" -x $GDAS/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}12 $RUNDIR/cmap.gdas.${yyyymmdd}12
$COPYGB -i3 -g"$gds" -x $GDAS/cpc.$yyyymmdd/precip.gldas.${yyyymmdd}18 $RUNDIR/cmap.gdas.${yyyymmdd}18

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`

done

### create configure file
${HOMEgldas}/ush/gldas_liscrd.sh $RUNSTARTDATE $RUNENDDATE 1534

### create lsf file

cp ${PARMgldas}/LIS.lsf.tmp LIS.lsf
echo "#BSUB -oo $RUNDIR/LIS.out"   >> LIS.lsf
echo "#BSUB -eo $RUNDIR/LIS.error" >> LIS.lsf
echo "cd $RUNDIR"                  >> LIS.lsf
echo "mpirun -n 112 ./LIS"            >> LIS.lsf

### 3) Produce initials noah.rst from 6-tile gdas restart files ----

### 3a) create gdas2gldas input file ----

echo "create gdas2gldqas input file fort.43 and copy into fort.41"
cp ${HOMEgldas}/parm/gdas2gldas.input fort.43
sed -i -e 's/date/'"$RUNSTARTDATE"'/g' -e 's/cyc/'"$cyc"'/g' fort.43
sed -i 's|/indirect/|'"$input1"'|g' fort.43
sed -i 's|/orogdir/|'"$topodir"'|g' fort.43
sed -i -e 's/noahmp/'"${model}"'/g' fort.43

### 3b) Use gdas2gldas to generate nemsio file and 
###     gldas_noah_rst/gldas_noahmp_rst to generate noah.rst ---

export LOG_FILE=gdas2gldas.log
rm $LOG_FILE
rm noah.rst

export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gdas2gldas -W 0:05 -x -n 6 \
        -R "span[ptile=6]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$HOMEgldas/ush/gdas2gldas.sh"

rm PET*ESMF_LogFile

export LOG_FILE=gldas_rst.log 
export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gldas_rst -W 0:02 -x -n 1 -w 'ended(gdas2gldas)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$HOMEgldas/ush/gldas_rst.sh"

### 4) run noah/noahmp model
bsub<$RUNDIR/LIS.lsf

### 5) using gdas2gldas to generate nemsio file for RUNENDDATE
###    use gldas_post to replace soil moisture and temperature
###    use gldas2gdas to produce 6-tile restart file 

if [ -s fort.41 ]; then
rm -rf fort.41
fi

### 5a) create input file for gdas2gldas

echo "create gdas2gldqas input file fort.45, and then cp fort.45 to for.41 to
avoid refill fort.41 in the first step"
cp ${PARMgldas}/gdas2gldas.input fort.45
sed -i -e 's/date/'"$RUNENDDATE"'/g' -e 's/cyc/'"$cyc"'/g' fort.45
sed -i 's|/indirect/|'"$input2"'|g' fort.45
sed -i 's|/orogdir/|'"$topodir"'|g' fort.45
sed -i -e 's/noahmp/'"${model}"'/g' fort.45

### 5b) use gdas2gldas to produce nemsio file
if [ -s sfc.gaussian.nemsio ]; then
rm -rf sfc.gaussian.nemsio
fi

export LOG_FILE=gdas2gldas_2nd.log
export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gdas2gldas_2nd -W 0:05 -x -n 6 -w 'ended(gldas_model)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$HOMEgldas/ush/gdas2gldas_2nd.sh"

### 5c) use gldas_post to replace soil moisture and temperature
yyyy=`echo $RUNENDDATE | cut -c1-4`
gbin=$RUNDIR/EXP901/NOAH/$yyyy/$RUNENDDATE/LIS.E901.${RUNENDDATE}00.NOAHgbin
sfcanl=sfc.gaussian.nemsio

export LOG_FILE=gldas_post.log
export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gldas_post -W 0:05 -x -n 1 -w 'ended(gdas2gldas_2nd)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$HOMEgldas/ush/gldas_post.sh $gbin $sfcanl"

### 5d) use gldas2gdas to create 6-tile restart tiles

echo "create gdas2gldqas input file fort.42"
cp ${PARMgldas}/gldas2gdas.input fort.42
sed -i 's|/orogdir/|'"$topodir"'|g' fort.42

# copy gdas netcdf tiles
gdate=${RUNENDDATE}
gdas_date=${gdate}.${cyc}0000
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile1.nc ./sfc_data.tile1.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile2.nc ./sfc_data.tile2.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile3.nc ./sfc_data.tile3.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile4.nc ./sfc_data.tile4.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile5.nc ./sfc_data.tile5.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile6.nc ./sfc_data.tile6.nc

chmod 744 sfc_data.tile*.nc

# copy soil type
cp ${FIXgldas}/FIX_T1534/stype_gfs_T1534.bfsa  ./stype_gfs_T1534.bfsa

LOG_FILE=gldas2gdas.log
export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gldas2gdas -W 0:05 -x -n 6 -w 'ended(gldas_post)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$HOMEgldas/ush/gldas2gdas.sh"

### 5e) archive gldas results
export LOG_FILE=gldas_archive.log
export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gldas_archive -W 0:05 -x -n 1 -w 'ended(gldas2gdas)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$HOMEgldas/ush/gldas_archive.sh $RUNSTARTDATE $RUNENDDATE"

echo $RUNDIR
