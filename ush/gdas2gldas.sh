#!/bin/bash
set -x

export HOMEgldas=/gpfs/dell2/emc/retros/noscrub/Youlong.Xia/GLDAS
mpirun ${HOMEgldas}/exec/gdas2gldas

exit
