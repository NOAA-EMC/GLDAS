#!/bin/ksh
#
#########################################################
# This script runs gldas from BDATE 00Z to GDATE 00Z 
#
# usage - lis.run.sh BDATE [GDATE]
#         BDATE/GDATE in yyyymmdd 
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

### define work directories

export HOMEgldas=/gpfs/dell2/emc/retros/noscrub/Youlong.Xia/GLDAS
export COM_OUT=/gpfs/dell2/emc/retros/noscrub/$USER/gldas.T1534.igbp.2019/output
export WORKDIR=/gpfs/dell2/ptmp/$USER/gldas.$BDATE
export GDAS=/gpfs/dell2/ptmp/$USER/force

### setup WORKDIR and model

export model=noah
export cyc0=00

rm -fr $WORKDIR
mkdir -p $WORKDIR
cd $WORKDIR

ln -s $HOMEGLDAS/fix/FIX_T1534 $WORKDIR/FIX
ln -s $HOMEGLDAS/exec/gldas_${model} $WORKDIR/LIS

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

### 3) Produce intials noah.rs from 6-tile gdas restart files ----

### 3a) create gdas2gldas input file ----

echo "create gdas2gldqas input file fort.41"
cp ${LISDIR}/parm/gdas2gldas.input fort.41
sed -i -e 's/date/'"RUNSTARTDATE"'/g' -e 's/cyc/'"$cyc0"'/g' fort.41
sed -i 's|/indirect/|'"$input1"'|g' fort.41
sed -i 's|/orogdir/|'"$topodir"'|g' fort.41

### 3b) Use gdas2gldas to generate nemsio file and 
###     gldas_rst to generate noah.rst ---

export LOG_FILE=gldas.log
SUM_FILE=summary.log
rm -rm $LOG_FILE $SUM_FILE
rm -rm noah.rst

export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gdas2gldas -W 0:15 -x -n 6 \
        -R "span[ptile=6]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$PWD/gdas2gldas.sh"

export OMP_NUM_THREADS=1
bsub -e $LOG_FILE -o $LOG_FILE -q $QUEUE -P $PROJECT_CODE -J gldas_res -W 0:01 -x -n 1 -w 'ended(gdas2gldas)' \
        -R "span[ptile=1]" -R "affinity[core(${OMP_NUM_THREADS}):distribute=balance]" "$PWD/gldas_rst.sh"

### 4) run noah/noahmp model
if [ -s noah.rst };
bsub<$WORKDIR/LIS.lsf
fi



# ------- create gldas2gdas input file for.42 ---------------------------

echo "create gdas2gldqas input file fort.42"
cp ${LISDIR}/parm/gdas2gldas.input fort.42
sed -i 's|/orogdir/|'"$topodir"'|g' fort.42



echo $RUNDIR
