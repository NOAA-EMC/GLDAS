 module model_grid

 use esmf
 use setup

 implicit none

 private

 integer, public                        :: i_gldas, j_gldas
 integer, public                        :: i_gdas, j_gdas
 integer, parameter, public             :: lsoil =4

 type(esmf_grid),  public               :: gldas_grid
 type(esmf_grid),  public               :: gdas_grid

 type(esmf_field)                       :: latitude_gldas_grid
 type(esmf_field)                       :: longitude_gldas_grid

 public :: define_gldas_grid
 public :: define_gdas_grid

 contains

 subroutine define_gdas_grid(npets)

 use netcdf

 implicit none

 integer, intent(in)  :: npets

 character(len=300) :: mosaic_file, grid_file1
 character(len=255), allocatable :: grid_files(:)

 integer :: error, extra, num_tiles_gdas_grid, tile, ncid
 integer :: dimid, varid, ii

 integer, allocatable         :: decomptile(:,:)

!-----------------------------------------------------------------------
! Open mosaic file.  Read number of tiles and the names of the
! grid files.
!-----------------------------------------------------------------------

 mosaic_file=trim(orog_dir_gdas_grid) // "/" // trim(mosaic_file_gdas_grid)

 print*,'open ',trim(mosaic_file)
 error = nf90_open(trim(mosaic_file), nf90_nowrite, ncid)
 call netcdf_err(error, 'opening mosaic file')

 error = nf90_inq_dimid(ncid, 'ntiles', dimid)
 call netcdf_err(error, 'getting tile id')

 error = nf90_inquire_dimension(ncid, dimid, len=num_tiles_gdas_grid)
 call netcdf_err(error, 'getting tile id')

 allocate(grid_files(num_tiles_gdas_grid))

 error = nf90_inq_varid(ncid, 'gridfiles', varid)
 call netcdf_err(error, 'getting gridfiles id')

 error = nf90_get_var(ncid, varid, grid_files)
 call netcdf_err(error, 'reading gridfiles')

 error = nf90_close(ncid)

!-----------------------------------------------------------------------
! Read first grid file and get dimesion of tiles.
!-----------------------------------------------------------------------

 ii = index(grid_files(1), ".nc")  ! strip off garbage characters

 grid_file1 = trim(orog_dir_gdas_grid) // "/" // grid_files(1)(1:ii+2)

 print*,'open ',trim(grid_file1)
 error = nf90_open(trim(grid_file1), nf90_nowrite, ncid)
 call netcdf_err(error, 'opening grid file')

 error = nf90_inq_dimid(ncid, 'nx', dimid)
 call netcdf_err(error, 'getting nx id')

 error = nf90_inquire_dimension(ncid, dimid, len=i_gdas)
 call netcdf_err(error, 'reading nx')

 error = nf90_close(ncid)

 i_gdas = i_gdas / 2
 j_gdas = i_gdas

 print*,"- GDAS TILES HAVE DIMESION OF ", i_gdas, j_gdas

!-----------------------------------------------------------------------
! Create ESMF grid object for the model grid.
!-----------------------------------------------------------------------

 extra = npets / num_tiles_gdas_grid

 allocate(decomptile(2,num_tiles_gdas_grid))

 do tile = 1, num_tiles_gdas_grid
   decomptile(:,tile)=(/1,extra/)
 enddo

 print*,"- CALL GridCreateMosaic FOR GDAS GRID"
 gdas_grid = ESMF_GridCreateMosaic(filename=trim(mosaic_file), &
                                  regDecompPTile=decomptile, &
                                  staggerLocList=(/ESMF_STAGGERLOC_CENTER, ESMF_STAGGERLOC_CORNER, &
                                                   ESMF_STAGGERLOC_EDGE1, ESMF_STAGGERLOC_EDGE2/), &
                                  indexflag=ESMF_INDEX_GLOBAL, &
                                  tileFilePath=trim(orog_dir_gdas_grid), rc=error)
 if(ESMF_logFoundError(rcToCheck=error,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
    call error_handler("IN GridCreateMosaic", error)


 end subroutine define_gdas_grid

 subroutine define_gldas_grid(npets)

 use nemsio_module

 implicit none

 integer, intent(in) :: npets

 character(len=50) :: nems_file

 integer :: i, j, rc, clb(2), cub(2)
 integer :: ip1_gldas, jp1_gldas
 integer(nemsio_intkind) :: iret

 real(esmf_kind_r8), allocatable  :: latitude(:,:)
 real(esmf_kind_r8), allocatable  :: longitude(:,:)
 real(esmf_kind_r8)               :: deltalon
 real(esmf_kind_r8), allocatable  :: slat(:), wlat(:)
 real(esmf_kind_r8), pointer      :: lat_src_ptr(:,:)
 real(esmf_kind_r8), pointer      :: lon_src_ptr(:,:)

 type(nemsio_gfile)               :: gfile
 type(esmf_polekind_flag)         :: polekindflag(2)

!-----------------------------------------------------------------------
! Get grid dimensios from gldas nemsio file.
!-----------------------------------------------------------------------

 print*,"- READ GLDAS FILE TO GET GRID DIMENSIONS"

 nems_file="./gldas.nemsio"

 call nemsio_open(gfile, nems_file, "read", iret=iret)
 if (iret /= 0) call error_handler("opening gldas nems file")

 call nemsio_getfilehead(gfile, iret=iret, dimx=i_gldas)
 if (iret /= 0) call error_handler("reading dimx")

 call nemsio_getfilehead(gfile, iret=iret, dimy=j_gldas)
 if (iret /= 0) call error_handler("reading dimy")

 call nemsio_close(gfile)

 print*,"- DIMENSIONS OF GLDAS DATA: ", i_gldas, j_gldas

!-----------------------------------------------------------------------
! Create esmf grid object for gldas grid.
!-----------------------------------------------------------------------

 ip1_gldas = i_gldas + 1
 jp1_gldas = j_gldas + 1

 polekindflag(1:2) = ESMF_POLEKIND_MONOPOLE

 print*,"- CALL GridCreate1PeriDim FOR gldas GAUSSIAN GRID."
 gldas_grid = ESMF_GridCreate1PeriDim(minIndex=(/1,1/), &
                                    maxIndex=(/i_gldas,j_gldas/), &
                                    polekindflag=polekindflag, &
                                    periodicDim=1, &
                                    poleDim=2,  &
                                    coordSys=ESMF_COORDSYS_SPH_DEG, &
                                    regDecomp=(/1,npets/),  &
                                    indexflag=ESMF_INDEX_GLOBAL, rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
   call error_handler("IN GridCreate1PeriDim", rc)

 print*,"- CALL FieldCreate FOR TARGET GRID LATITUDE."
 latitude_gldas_grid = ESMF_FieldCreate(gldas_grid, &
                                   typekind=ESMF_TYPEKIND_R8, &
                                   staggerloc=ESMF_STAGGERLOC_CENTER, &
                                   name="gldas_grid_latitude", rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
   call error_handler("IN FieldCreate", rc)

 print*,"- CALL FieldCreate FOR TARGET GRID LONGITUDE."
 longitude_gldas_grid = ESMF_FieldCreate(gldas_grid, &
                                   typekind=ESMF_TYPEKIND_R8, &
                                   staggerloc=ESMF_STAGGERLOC_CENTER, &
                                   name="gldas_grid_longitude", rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
   call error_handler("IN FieldCreate", rc)

 allocate(longitude(i_gldas,j_gldas))
 allocate(latitude(i_gldas,j_gldas))

 deltalon = 360.0_esmf_kind_r8 / real(i_gldas,kind=esmf_kind_r8)
 do i = 1, i_gldas
   longitude(i,:) = real((i-1),kind=esmf_kind_r8) * deltalon
 enddo

 allocate(slat(j_gldas))
 allocate(wlat(j_gldas))
 call splat(4, j_gldas, slat, wlat)

 do i = 1, j_gldas
    latitude(:,i) = 90.0_esmf_kind_r8 - (acos(slat(i))* 180.0_esmf_kind_r8 / &
                   (4.0_esmf_kind_r8*atan(1.0_esmf_kind_r8)))
!  latitude(:,j_gldas-i+1) = 90.0_esmf_kind_r8 - (acos(slat(i))* 180.0_esmf_kind_r8 / &
!                 (4.0_esmf_kind_r8*atan(1.0_esmf_kind_r8)))
 enddo

 deallocate(slat, wlat)

 print*,"- CALL FieldScatter FOR gldas GRID LONGITUDE."
 call ESMF_FieldScatter(longitude_gldas_grid, longitude, rootpet=0, rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
    call error_handler("IN FieldScatter", rc)

 print*,"- CALL FieldScatter FOR gldas GRID LATITUDE."
 call ESMF_FieldScatter(latitude_gldas_grid, latitude, rootpet=0, rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
    call error_handler("IN FieldScatter", rc)

 print*,"- CALL GridAddCoord FOR gldas GRID."
 call ESMF_GridAddCoord(gldas_grid, &
                        staggerloc=ESMF_STAGGERLOC_CENTER, rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
    call error_handler("IN GridAddCoord", rc)

 print*,"- CALL GridGetCoord FOR gldas GRID X-COORD."
 nullify(lon_src_ptr)
 call ESMF_GridGetCoord(gldas_grid, &
                        staggerLoc=ESMF_STAGGERLOC_CENTER, &
                        coordDim=1, &
                        farrayPtr=lon_src_ptr, rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
    call error_handler("IN GridGetCoord", rc)

 print*,"- CALL GridGetCoord FOR gldas GRID Y-COORD."
 nullify(lat_src_ptr)
 call ESMF_GridGetCoord(gldas_grid, &
                        staggerLoc=ESMF_STAGGERLOC_CENTER, &
                        coordDim=2, &
                        computationalLBound=clb, &
                        computationalUBound=cub, &
                        farrayPtr=lat_src_ptr, rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
    call error_handler("IN GridGetCoord", rc)

 do j = clb(2), cub(2)
   do i = clb(1), cub(1)
     lon_src_ptr(i,j) = longitude(i,j)
     if (lon_src_ptr(i,j) > 360.0_esmf_kind_r8) lon_src_ptr(i,j) = lon_src_ptr(i,j) - 360.0_esmf_kind_r8
     lat_src_ptr(i,j) = latitude(i,j)
     if (i==1 .and.j==1) print*,'lat/lon point 11 ',latitude(i,j), longitude(i,j)
     if (i==i_gldas .and.j==j_gldas) print*,'lat/lon point last point ',latitude(i,j), longitude(i,j)
   enddo
 enddo


 print*,"- CALL GridAddCoord FOR gldas GRID."
 call ESMF_GridAddCoord(gldas_grid, &
                        staggerloc=ESMF_STAGGERLOC_CORNER, rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
    call error_handler("IN GridAddCoord", rc)

 print*,"- CALL GridGetCoord FOR gldas GRID X-COORD."
 nullify(lon_src_ptr)
 call ESMF_GridGetCoord(gldas_grid, &
                        staggerLoc=ESMF_STAGGERLOC_CORNER, &
                        coordDim=1, &
                        farrayPtr=lon_src_ptr, rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
    call error_handler("IN GridGetCoord", rc)

 print*,"- CALL GridGetCoord FOR gldas GRID Y-COORD."
 nullify(lat_src_ptr)
 call ESMF_GridGetCoord(gldas_grid, &
                        staggerLoc=ESMF_STAGGERLOC_CORNER, &
                        coordDim=2, &
                        computationalLBound=clb, &
                        computationalUBound=cub, &
                        farrayPtr=lat_src_ptr, rc=rc)
 if(ESMF_logFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)) &
    call error_handler("IN GridGetCoord", rc)

 do j = clb(2), cub(2)
   do i = clb(1), cub(1)
     lon_src_ptr(i,j) = longitude(i,1) - (0.5_esmf_kind_r8*deltalon)
     if (lon_src_ptr(i,j) > 360.0_esmf_kind_r8) lon_src_ptr(i,j) = lon_src_ptr(i,j) - 360.0_esmf_kind_r8
     if (j == 1) then
!      lat_src_ptr(i,j) = -90.0_esmf_kind_r8
       lat_src_ptr(i,j) = 90.0_esmf_kind_r8
       cycle
     endif
     if (j == jp1_gldas) then
       lat_src_ptr(i,j) = -90.0_esmf_kind_r8
!      lat_src_ptr(i,j) =  90.0_esmf_kind_r8
       cycle
     endif
     lat_src_ptr(i,j) = 0.5_esmf_kind_r8 * (latitude(i,j-1)+ latitude(i,j))
   enddo
 enddo

 print*,'lat/lon corner',maxval(lat_src_ptr),minval(lat_src_ptr),maxval(lon_src_ptr),minval(lon_src_ptr)

 deallocate(latitude,longitude)

 end subroutine define_gldas_grid

 end module model_grid
