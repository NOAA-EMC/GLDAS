#!/bin/sh --login

#BSUB -L /bin/sh
#BSUB -P GFS-T2O
#BSUB -J jgdas_gldas_12
#BSUB -o gdas_gldas.o%J
#BSUB -e gdas_gldas.o%J
#BSUB -W 02:30
##BSUB -q debug
#BSUB -n 24                      # number of tasks
#BSUB -R span[ptile=1]          # 1 task per node
#BSUB -cwd /gpfs/dell2/ptmp/Hang.Lei/output
#BSUB -R affinity[core(1):distribute=balance]
#BSUB -q devonprod
#BSUB -M 3072
#BSUB -extsched 'CRAYLINUX[]'

set -x

export NODES=1
export ntasks=24
export ptile=1
export threads=1

export CDATE=2017030806


#############################################################
export KMP_AFFINITY=disabled

export PDY=`date -u +%Y%m%d`
export PDY=20180925

export PDY1=`expr $PDY - 1`

export cyc=12
export cycle=t${cyc}z

set -xa
export PS4='$SECONDS + '
date

####################################
##  Load theUtilities module
#####################################
module load EnvVars/1.0.2
module load ips/18.0.1.163
module load CFP/2.0.1
module load impi/18.0.1
module load lsf/10.1
module load prod_util/1.1.0
module load prod_envir/1.0.2
module use -a /gpfs/dell1/nco/ops/nwpara/modulefiles/compiler_prod/ips/18.0.1
module load grib_util/1.1.0
###########################################
# Now set up environment
###########################################
module use -a /gpfs/dell1/nco/ops/nwpara/modulefiles/
module list

############################################
# GDAS META PRODUCT GENERATION
############################################
# set envir=prod or para to test with data in prod or para
 export envir=para
# export envir=prod

export SENDCOM=YES
export KEEPDATA=YES
export job=gdas_gldas_${cyc}
export pid=${pid:-$$}
export jobid=${job}.${pid}

##############################################
# Define COM, COMOUTwmo, COMIN  directories
##############################################
if [ $envir = "prod" ] ; then
#  This setting is for testing with GDAS (production)
  export COMIN=/gpfs/hps/nco/ops/com/nawips/prod/${RUN}.${PDY}         ### NCO PROD
  export COMROOT=/gpfs/hps/nco/ops/com
else
# export COMIN=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/${RUN}.${PDY}/${cyc}/nawips ### EMC PARA Realtime
# export COMINgdas=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/${RUN} ### EMC PARA Realtime
  export COMIN=/gpfs/dell2/emc/modeling/noscrub/
  export COMOUT=/gpfs/dell2/emc/modeling/noscrub/
fi

if [ $SENDCOM = YES ] ; then
  mkdir -m 775 -p $COMOUT $COMOUTncdc $COMOUTukmet $COMOUTecmwf
fi

# Set user specific variables
#############################################################
#export NWTEST=/gpfs/hps/emc/global/noscrub/emc.glopara/svn/gfs/work
#export PARA_CONFIG=$NWTEST/gdas.${gdas_ver}/driver/para_config.gdas_gldas
#export JOBGLOBAL=$NWTEST/gdas.${gdas_ver}/jobs
export JOBGLOBAL=./jobs

#############################################################
# Execute job
#############################################################
$JOBGLOBAL/JGDAS_GLDAS

exit
