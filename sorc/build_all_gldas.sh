#!/bin/bash
set -eux

build_dir=`pwd`
logs_dir=$build_dir/logs
if [ ! -d $logs_dir  ]; then
  echo "Creating logs folder"
  mkdir $logs_dir
fi

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  echo "Creating ../exec folder"
  mkdir ../exec
fi

#------------------------------------
# build everything except gldas_model
#------------------------------------
echo " .... Building all except gldas_model .... "
./build.sh > $logs_dir/build.log 2>&1
echo;echo " .... Build system finished .... "

#------------------------------------
# build gldas_model
#------------------------------------
echo " .... Building gldas_model .... "
./build_gldas_model.sh > $logs_dir/build_gldas_model.log 2>&1
echo;echo " .... Build system finished .... "

exit 0
