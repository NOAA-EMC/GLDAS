#!/bin/sh
if [ $# -lt 2 ]; then
echo "usage: $0 gldas.gbin gdas.sfcanl"
exit
fi
gbin=$1
sfcanl=$2

export LISDIR=/gpfs/dell2/emc/retros/noscrub/Youlong.Xia/gldas.v2.3.0

rm -f fort.11 fort.12 fort.22
cp $gbin fort.11
cp $sfcanl fort.12

$LISDIR/exec/gfs_gdas_gldas_gldas2gdas

cp fort.22 ${sfcanl}.gldas
rm -f fort.11 fort.12 fort.22

echo ${sfcanl}.gldas

