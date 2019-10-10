#!/bin/sh
if [ $# -lt 2 ]; then
echo "usage: $0 gldas.gbin gdas.sfcanl"
exit
fi
gbin=$1
sfcanl=$2

export LISDIR=/gpfs/dell2/emc/retros/noscrub/Youlong.Xia/GLDAS

rm -f fort.11 fort.12 fort.22
cp $gbin fort.11
cp $sfcanl fort.12

$LISDIR/exec/gldas_post

cp fort.22 ${sfcanl}.gldas
rm -f fort.11 fort.12 fort.22

echo ${sfcanl}.gldas

