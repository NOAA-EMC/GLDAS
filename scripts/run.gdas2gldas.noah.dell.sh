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

if [ $# -lt 1 ]; then
echo "usage: ksh $0 yyyymmdd"
exit
fi

BDATE=$1
export LISDIR=/gpfs/dell2/emc/retros/noscrub/Youlong.Xia/GLDAS
export RUNDIR=/gpfs/dell2/ptmp/$USER/gldas.$BDATE
mkdir -p $RUNDIR
cd $RUNDIR

mpirun ${LISDIR}/exec/gdas2gldas

exit
