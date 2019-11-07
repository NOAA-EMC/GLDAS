#!/bin/bash
set -x

cd $RUNDIR

export pgm=gldas2gdas
  . prep_step

echo 'running  gldas2gdas'
  startmsg
  $APRUN_GAUSSIAN $EXECgldas/gldas2gdas >> $pgmout 2>errfile
  export err=$?; err_chk

exit
