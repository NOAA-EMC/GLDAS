#!  /bin/csh -fx

cd make/MAKDEP
gmake
cd .. 
gmake realclean
gmake -f Makefile.noah
gmake realclean
gmake -f Makefile.noahmp

