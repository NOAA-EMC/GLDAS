#!  /bin/csh -fx

cd make/MAKDEP
gmake
cd .. 
gmake realclean
gmake
