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

export CURRENTD=$PDY
echo $CURRENTD

# GET START DATE
export RUNSTARTDATE=`finddate.sh $CURRENTD d-3`
export RUNENDDATE=$CURRENTD

module purge
module load EnvVars/1.0.2
module load ips/18.0.1.163
module load impi/18.0.1
module load lsf/10.1
module use /usrx/local/dev/modulefiles
module load NetCDF/4.5.0

QUEUE="debug"
PROJECT_CODE="NLDAS-T2O"

echo $RUNSTARTDATE
echo "USING: $RUNSTARTDATE to GET START DATA"
echo "RUNNING THROUGH: $RUNENDDATE"

yyyymmdd0=`sh $FINDDATE $RUNSTARTDATE d-1`

echo "GLDAS runs from $yyyymmdd0 00Z to $yyyymmdd2 00Z"

# As CPC precipitation is from 12z to 12z, the script needs to get one more
# day gdas data to disaggregate daily CPC precipitation value to hourly

### define directories

export HOMEgldas=/gpfs/dell2/emc/retros/noscrub/$LOGNAME/GLDAS
export COM_OUT=/gpfs/dell2/emc/retros/noscrub/$LOGNAME/gldas.T1534.igbp.2019/output
export WORKDIR=/gpfs/dell2/ptmp/$LOGNAME
export GDAS=/gpfs/dell2/ptmp/$LOGNAME/force
export RUNDIR=${WORKDIR}/gldas.$RUNSTARTDATE

export input1=$GDAS/gdas.$RUNSTARTDATE
export input2=$GDAS/gdas.$RUNSTARTDATE
export topodir=/gpfs/dell2/emc/modeling/noscrub/George.Gayno/fv3gfs.git/global-workflow/fix/fix_fv3_gmted2010/C768/

### setup WORKDIR and model

export model=noah
export cyc0=00

rm -fr $WORKDIR
mkdir -p $WORKDIR
cd $WORKDIR

ln -s $HOMEgldas/fix/FIX_T1534 $WORKDIR/FIX
ln -s $HOMEgldas/exec/gldas_${model} $WORKDIR/LIS

### 1) Get all gdas data and 6-tile netcdf restart data -----

yyyymmdd=$yyyymmdd0
while [ $yyyymmdd -lt $RUNENDDATE ];do

$HOMEgldas/scripts/gldas_get_data.sh $yyyymmdd

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`
done

### 2) Get CPC daily precip and spatially and temporally disaggreated ---

yyyymmdd=$RUNSTARTDATE
while [ $yyyymmdd -lt $RUNENDDATE ];do

$HOMEgldas/scripts/gldas_forcing.sh $yyyymmdd

yyyymmdd=`sh $FINDDATE $yyyymmdd d+1`
done

### 3) Produce initials noah.rst from 6-tile gdas restart files ----

### 3a) create gdas2gldas input file ----

echo "create gdas2gldqas input file fort.41"
cp ${HOMEgldas}/parm/gdas2gldas.input fort.41
sed -i -e 's/date/'"$RUNSTARTDATE"'/g' -e 's/cyc/'"$cyc0"'/g' fort.41
sed -i 's|/indirect/|'"$input1"'|g' fort.41
sed -i 's|/orogdir/|'"$topodir"'|g' fort.41

### 3b) Use gdas2gldas to generate nemsio file and 
###     gldas_rst to generate noah.rst ---

export LOG_FILE=gldas.log
SUM_FILE=summary.log
rm -rm $LOG_FILE $SUM_FILE
rm -rm noah.rst

export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gdas2gldas -W 0:05 -x -n 6 \
        -R "span[ptile=6]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$PWD/gdas2gldas.sh"

export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gldas_res -W 0:02 -x -n 1 -w 'ended(gdas2gldas)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$PWD/gldas_rst.sh"

### 4) run noah/noahmp model
if [ -s noah.rst ]; then
bsub<$RUNDIR/LIS.lsf
fi

### 5) using gdas2gldas to generate nemsio file for RUNENDDATE
###    use gldas_post to replace soil moisture and temperature
###    use gldas2gdas to produce 6-tile restart file 

if [-s fort.41 ]; then
rm -rm fort.41
fi

### 5a) create input file for gdas2gldas

echo "create gdas2gldqas input file fort.41"
cp ${HOMEgldas}/parm/gdas2gldas.input fort.41
sed -i -e 's/date/'"$RUNENDDATE"'/g' -e 's/cyc/'"$cyc0"'/g' fort.41
sed -i 's|/indirect/|'"$input2"'|g' fort.41
sed -i 's|/orogdir/|'"$topodir"'|g' fort.41

### 5b) use gdas2gldas to produce nemsio file
if [ -s sfc.gaussian.nemsio ]; then
rm -rm sfc.gaussian.nemsio
fi

export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gdas2gldas -W 0:05 -x -n 6 -w 'ended(LIS)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$PWD/gdas2gldas.sh"

### 5c) use gldas_post to replace soil moisture and temperature
yyyy=`echo $RUNENDDATE | cut -c1-4`
gbin=$RUNDIR/EXP901/NOAH/$yyyy/$RUNENDDATE/LIS.E901.${RUNENDDATE}00.NOAHgbin
fcanl=sfc.gaussian.nemsio

export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gldas_post -W 0:02 -x -n 1 -w 'ended(gdas2gldas)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$PWD/gldas_post.sh $gbin $sfcanl"

### 5d) use gldas2gdas to create 6-tile restart tiles

echo "create gdas2gldqas input file fort.42"
cp ${HOMEgldas}/parm/gdas2gldas.input fort.42
sed -i 's|/orogdir/|'"$topodir"'|g' fort.42

# copy gdas netcdf tiles
gdate=${RUNENDDATE}
gdas_date=${gdate}.${cyc0}0000
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile1.nc ./sfc_data.tile1.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile2.nc ./sfc_data.tile2.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile3.nc ./sfc_data.tile3.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile4.nc ./sfc_data.tile4.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile5.nc ./sfc_data.tile5.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile6.nc ./sfc_data.tile6.nc

chmod 744 sfc_data.tile*.nc

# copy soil type
cp ${HOMEgldas}/fix/FIX_T1534/stype_gfs_T1534.bfsa  ./stype_gfs_T1534.bfsa

export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gldas2gdas -W 0:05 -x -n 6 -w 'ended(gdas_post)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$PWD/gldas2gdas.sh"

### 5e) archive gldas results

export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gldas_archive -W 0:05 -x -n 1 -w 'ended(gldas2gdas)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$PWD/gldas_archive.sh $RUNSTARTDATE $RUNENDDATE"

echo $RUNDIR
