#!/bin/bash
set -x

cd $RUNDIR
 export pgm=gdas2gldas
  . prep_step

### to produce edate input file to avoid refill sdate input file
cp fort.45 fort.41

echo 'running gdas2gldas'
  startmsg
  $APRUN_GAUSSIAN ${EXECgldas}/gdas2gldas  >>$pgmout 2>errfile
  export err=$?; err_chk

exit
