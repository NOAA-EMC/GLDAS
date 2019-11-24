#!/bin/ksh

##############################################################
# This script generate noah.rst from nemsio file 
# (sfc.gaussian.nemsio produced from gdas2gldas
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

cp ${FIXgldas}/lmask_gfs_T1534.bfsa fort.11
cp $sfcanl fort.12

startmsg
${EXECgldas}/gldas_${model}_rst >> $pgmout 2>>errfile
export err=$?; err_chk

mv sfc.gaussian.nemsio sfc.gaussian.nemsio.$RUNSTARTDATE

exit
