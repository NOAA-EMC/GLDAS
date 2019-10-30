#!/bin/sh --login

date

#BSUB -L /bin/sh
#BSUB -P GFS-T2O
#BSUB -J jgdas_gldas_12
#BSUB -o gdas_gldas.o%J
#BSUB -e gdas_gldas.o%J
#BSUB -W 02:30
#BSUB -q debug
##BSUB -q devonprod
#BSUB -n 24                      # number of tasks
#BSUB -R span[ptile=24]          # tasks per node
#BSUB -cwd /gpfs/dell2/ptmp/$LOGNAME/output
#BSUB -R affinity[core(1):distribute=balance]
#BSUB -M 3072
#BSUB -extsched 'CRAYLINUX[]'

set -x

export NODES=1
export ntasks=24
export ptile=24
export threads=1

export CDATE=2019102900


#############################################################
export KMP_AFFINITY=disabled

export PDY=`date -u +%Y%m%d`
export PDY=20191029

export PDY1=`expr $PDY - 1`

export cyc=00
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
  export HOMEgldas=/nwprod/gldas.${gldas_ver}
  export COMIN=/gpfs/dell1/nco/ops/com/gfs/prod/${RUN}.${PDY}         ### NCO PROD
  export COMROOT=/gpfs/dell1/nco/ops/com
  export DCOMROOT=/gpfs/dell1/nco/ops/dcom
else
# export COMIN=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/${RUN}.${PDY}/${cyc}/nawips ### EMC PARA Realtime
# export COMINgdas=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/${RUN} ### EMC PARA Realtime
  export workdir=/gpfs/dell2/emc//retros/noscrub/$LOGNAME
  export HOMEgldas=$workdir/GLDAS
  export COMROOT=$workdir/com
  export DCOMROOT=$workdir/dcom
#  export COMINgdas=$COMROOT
#  export DCOMIN=$DCOMROOT
  export COMIN=$workdir/comin
  export COMOUT=$workdir/comout
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
echo $JOBGLOBAL/JGDAS_GLDAS
$JOBGLOBAL/JGDAS_GLDAS

exit

