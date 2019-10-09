sfc_noahmp_drv.o sfc_noahmp_drv.d : sfc_noahmp_drv.F
sfc_noahmp_drv.o : machine.o
sfc_noahmp_drv.o : funcphys.o
sfc_noahmp_drv.o : physcons.o
sfc_noahmp_drv.o : module_sf_noahmplsm.o
sfc_noahmp_drv.o : module_sf_noahmp_glacier.o
sfc_noahmp_drv.o : noahmp_tables.o
sfc_noahmp_drv.o : kwm_date_utilities.o
