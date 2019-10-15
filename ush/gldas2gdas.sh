#!/bin/bash

#BSUB -oo log
#BSUB -eo log
#BSUB -q debug
#BSUB -P NLDAS-T2O
#BSUB -J gldas
#BSUB -W 0:05
#BSUB -x                 # run not shared
#BSUB -n 6               # total tasks
#BSUB -R span[ptile=6]   # tasks per node
#BSUB -R affinity[core(1):distribute=balance]

set -x

module purge
module load EnvVars/1.0.2
module load ips/18.0.1.163
module load impi/18.0.1
module load lsf/10.1
module use /usrx/local/dev/modulefiles
module load NetCDF/4.5.0

finddate=finddate.sh
if [ $# -lt 1 ]; then
echo "usage: ksh $0 yyyymmdd [yyyymmdd2]"
exit
fi

gdate=`sh $FINDDATE $1 d+2`
BDATE=$1
cyc0=00

export GDAS=/gpfs/dell2/ptmp/$USER/force
export GLDASDIR=/gpfs/dell2/emc/retros/noscrub/Youlong.Xia/GLDAS
export RUNDIR=/gpfs/dell2/ptmp/$USER/gldas.$BDATE
mkdir -p $RUNDIR
cd $RUNDIR

# copy gdas netcdf tiles
gdas_date=${gdate}.${cyc0}0000
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile1.nc ./sfc_data.tile1.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile2.nc ./sfc_data.tile2.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile3.nc ./sfc_data.tile3.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile4.nc ./sfc_data.tile4.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile5.nc ./sfc_data.tile5.nc
cp ${GDAS}/gdas.${gdate}/${gdas_date}.sfcanl_data.tile6.nc ./sfc_data.tile6.nc

chmod 744 sfc_data.tile*.nc

# copy soil type
cp ${GLDASDIR}/fix/FIX_T1534/stype_gfs_T1534.bfsa  ./stype_gfs_T1534.bfsa

# copy gldas restart file

# On Dell
# the gldas nemsio file
cp gdas.t${cyc1}z.sfcanl.nemsio.gldas.${gdate} ./gldas.nemsio

mpirun ${GLDASDIR/exec/gldas2gdas

exit
