#!/bin/bash
set -eux

source ./machine-setup.sh > /dev/null 2>&1

if [[ "$target" != "NULL" ]]; then
  moduledir=`dirname $(readlink -f ../modulefiles)`
  set +x
  module use ${moduledir}
  module load gldas.${target}
  module list
  set -x
fi

# Check final exec folder exists
if [ ! -d "../exec" ]; then
  mkdir ../exec
fi

export target

cd gldas_model.fd/make/MAKDEP
gmake clean
gmake

cd ..
gmake -f Makefile.noah realclean
gmake -f Makefile.noah
gmake -f Makefile.noah install

#gmake -f Makefile.noahmp realclean
#gmake -f Makefile.noahmp
#gmake -f Makefile.noahmp install

exit
