#!/bin/sh
if [ $# -lt 1 ]; then
echo "usage: $0 yyyymmdd"
exit
fi
yyyymmdd=$1
echo $yyyymmdd

fpath=./
gpath=./

mkdir -p $fpath
mkdir -p $gpath

rm -f fort.11 fort.12 fort.22
cp $gpath/LIS.E901.${yyyymmdd}00.NOAHgbin fort.11
cp $fpath/gdas.t00z.sfcanl.nemsio fort.12

./gfs_gdas_gldas_gldas2gdas

cp fort.22 $fpath/gdas.t00z.sfcanl.nemsio.gldas
rm -f fort.11 fort.12 fort.22

