#!/bin/sh
set -eu
#------------------------------------
# USER DEFINED STUFF:
#
# USE_PREINST_LIBS: set to "true" to use preinstalled libraries.
#                   Anything other than "true"  will use libraries locally.
#------------------------------------

export USE_PREINST_LIBS="true"

#------------------------------------
# END USER DEFINED STUFF
#------------------------------------

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
# build gdas2gldas
#------------------------------------
echo " .... Building gdas2gldas .... "
./build_gdas2gldas.sh > $logs_dir/build_gdas2gldas.log 2>&1

#------------------------------------
# build gldas2gdas
#------------------------------------
echo " .... Building gldas2gdas .... "
./build_gldas2gdas.sh > $logs_dir/build_gldas2gdas.log 2>&1

#------------------------------------
# build gldas_forcing
#------------------------------------
echo " .... Building gldas_forcing .... "
./build_gldas_forcing.sh > $logs_dir/build_gldas_forcing.log 2>&1

#------------------------------------
# build gldas_post
#------------------------------------
echo " .... Building gldas_post .... "
./build_gldas_post.sh > $logs_dir/build_gldas_post.log 2>&1

#------------------------------------
# build gldas_rst
#------------------------------------
echo " .... Building gldas_rst .... "
./build_gldas_rst.sh > $logs_dir/build_gldas_rst.log 2>&1

#------------------------------------
# build gldas_model
#------------------------------------
echo " .... Building gldas_model .... "
./build_gldas_model.sh > $logs_dir/build_gldas_model.log 2>&1
echo;echo " .... Build system finished .... "

exit 0
