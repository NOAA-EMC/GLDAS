#!/bin/ksh

##############################################################
# This script generate noah.rst from nemsio file 
# (sfc.gaussian.nemsioproduced from gdas2gldas
# Usage:     gldas_rst.sh
# History:   2019.05  Jesse Meng   original script
#            2019.10  Youlong Xia  modified script
##############################################################

cd ${RUNDIR}

export pgm=gldas_rst
  . prep_step

export sfcanl=sfc.gaussian.nemsio
if [ ! -s $sfcanl ]; then echo "$sfcanl produced from gdas2gldas CANNOT FIND;
STOP!"; exit; fi

if [ -s fort.11 ]; then
rm -f fort.11
fi

if [ -s fort.12 ]; then
rm -f fort.12
fi

ln -s ${HOMEgldas}/fix/FIX_T1534/lmask_gfs_T1534.bfsa fort.11
ln -s $sfcanl fort.12

cp ${HOMEgldas}/exec/gldas_${model}_rst gldas_rst
startmsg
./gldas_rst >> $pgmout 2>>errfile
export err=$?; err_chk

cp fort.22 ${sfcanl}.gldas
rm -f fort.11 fort.12 fort.22
