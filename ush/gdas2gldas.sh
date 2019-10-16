#!/bin/bash
set -x

cd $RUNDIR
 export pgm=gdas2gldas
  . prep_step

echo 'running gdas2gldas'
  startmsg
  mpirun ${HOMEgldas}/exec/gdas2gldas  >>$pgmout 2>errfile
  export err=$?; err_chk

exit
