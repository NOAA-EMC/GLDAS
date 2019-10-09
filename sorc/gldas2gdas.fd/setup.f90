 module setup

 character(len=200) :: orog_dir_gdas_grid

 contains


 subroutine namelist_read

 implicit none

 integer :: error 

 namelist /config/ orog_dir_gdas_grid

 open(42, file="./fort.42", iostat=error)
 if (error /= 0) call error_handler("OPENING SETUP NAMELIST.", error)
 read(42, nml=config, iostat=error)
 if (error /= 0) call error_handler("READING SETUP NAMELIST.", error)
 close (42)

 end subroutine namelist_read

 end module setup
