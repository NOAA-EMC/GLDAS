set -x
date

EXECDIR=../exec

cp -p gldas_post.fd/gldas_post $EXECDIR

cp -p gldas_forcing.fd/gldas_forcing  $EXECDIR

cp -p gldas_model.fd/gldas_noah  $EXECDIR

cp -p gldas_model.fd/gldas_noahmp  $EXECDIR

cp -p gldas_rst.fd/gldas_noah_rst $EXECDIR

cp -rp gldas_rst.fd/gldas_noahmp_rst $EXECDIR

cp -rp gdas2gldas.fd/gdas2gldas $EXECDIR

cp -rp gldas2gdas.fd/gldas2gdas $EXECDIR
date

