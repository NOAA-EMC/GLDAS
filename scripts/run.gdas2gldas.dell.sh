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

WORKDIR=/gpfs/dell2/ptmp/$LOGNAME/gdas2gldas
rm -fr $WORKDIR
mkdir -p $WORKDIR
cd $WORKDIR

mpirun /gpfs/dell2/emc/retros/noscrub/Youlong.Xia/GLDAS/exec/gdas2gldas

exit
