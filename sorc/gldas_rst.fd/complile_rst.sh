#!/bin/sh
set -x
date

cd noah
make clean
make
cp gldas_noah_rst ../

cd ..
cd noahmp
make clean 
make
cp gldas_noahmp_rst ../
