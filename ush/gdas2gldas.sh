#!/bin/bash
set -x

cd $RUNDIR
 export pgm=gdas2gldas
  . prep_step

cp fort.43 fort.41

echo 'running gdas2gldas'
  startmsg
  $APRUN_GAUSSIAN ${EXECgldas}/gdas2gldas  >>$pgmout 2>errfile
  export err=$?; err_chk

exit
