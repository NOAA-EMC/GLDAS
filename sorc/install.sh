set -x
date

EXECDIR=../exec

cp -p gfs_gdas_gldas_gldas2gdas.fd/gfs_gdas_gldas_gldas2gdas $EXECDIR

cp -p gfs_gdas_gldas_precip.fd/gfs_gdas_gldas_precip  $EXECDIR

cp -p gfs_gdas_gldas_LIS.fd/LIS  $EXECDIR/gfs_gdas_gldas_LIS

cp -p gfs_gdas_gldas_rst.fd/gfs_gdas_gldas_rst $EXECDIR
date

