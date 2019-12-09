!---- - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --
! This program creats GLDAS noahrst from GFS sfcanl.nemsio
!
! input
!  fort.11 lmask_gfs_T${JCAP}.bfsa
!  fort.12 gfs.t00z.sfcanl.nemsio
!
! output
!  fort.60 noah.rst
!
! 20190509 Jesse Meng
!-- - - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --
!
  use nemsio_module
  implicit none
!
!---------------------------------------------------------------------------
  type(nemsio_gfile) :: gfile
  character(255) cin
  real,allocatable  :: data(:,:)
!---------------------------------------------------------------------------
!--- nemsio meta data
  integer nrec,im,jm,lm,idate(7),nfhour,tlmeta,nsoil,fieldsize
  real,allocatable       :: slat(:), dx(:)
  real*8,allocatable       :: lat(:)
  character(16),allocatable:: recname(:),reclevtyp(:)
  integer,allocatable:: reclev(:)
!---------------------------------------------------------------------------
!--- local vars
  character(3) cmon
  character(32) ctldate,varname
  character(35) sweep_blanks
  real*8 dxctl,radi
  integer i,j,jj,k,krec,iret,io_unit,idrt,n
  integer itmp, icmc, iswe, isnd, ismc, islc, istc
  character*3 var3(3)
  integer idx3(3)

  integer mx
  integer my
  real mxmy
  real, allocatable :: sdata(:,:)
  real, allocatable :: lmasknoah(:,:)
  real, allocatable :: lmaskgfs(:,:)
  real, allocatable :: vtype(:,:)
  real, allocatable :: tmpsfc(:,:)
  real, allocatable :: cmc(:,:)
  real, allocatable :: sneqv(:,:)
  real, allocatable :: snowh(:,:)
  real, allocatable :: smc(:,:,:)
  real, allocatable :: stc(:,:,:)
  real, allocatable :: slc(:,:,:)
  real, allocatable :: ch(:,:)

  real, allocatable  :: head1(:)

  integer vclass  
  integer nch
  real, allocatable  :: noah(:)

!  real undef(mx,my)

!  undef = 9.99E+20
!  undef = -999.

  vclass = 1
  ch = 0.0001
!--------------------------------------------------------------------------
!***  read noah lmask
!---------------------------------------------------------------------------
  
!  open(11,file='fort.11',form='unformatted',status='unknown')

!  read(11) lmasknoah 
!  read(11) lmasknoah
!  read(11) lmasknoah
  
!  close(11)

!  nch = 0
!  do j = 1, my
!  do i = 1, mx
!     if ( lmasknoah(i,j) == 1.0 ) nch = nch + 1
!  enddo
!  enddo
!  allocate(noah(nch))

!---------------------------------------------------------------------------
!
  call nemsio_init(iret=iret)
  if(iret/=0) print *,'ERROR: nemsio_init '
!
!---------------------------------------------------------------------------
!***  read gfs.t00z.sfcanl.nemsio
!---------------------------------------------------------------------------
!--- open sfnanl file for reading
!  
  cin='fort.12'
!
  call nemsio_open(gfile,trim(cin),'READ',iret=iret)
  if(iret/=0) print *,'Error: open nemsio file,',trim(cin),' iret=',iret
!
  call nemsio_getfilehead(gfile,iret=iret,nrec=nrec,dimx=im,dimy=jm, &
    dimz=lm,idate=idate,nfhour=nfhour,                               &
    nsoil=nsoil,tlmeta=tlmeta)
  print* , im, jm, lm, tlmeta
!
   fieldsize=im*jm
   allocate(recname(nrec),reclevtyp(nrec),reclev(nrec))
   allocate(lat(fieldsize),slat(jm),dx(fieldsize))
   call nemsio_getfilehead(gfile,iret=iret,recname=recname,          &
       reclevtyp=reclevtyp,reclev=reclev)
!
  call nemsio_close(gfile,iret=iret)
!
  call nemsio_finalize()
!
!---------------------------------------------------------------------------
!*** read sfnanl.nemsio
!---------------------------------------------------------------------------
!
  mx=im
  my=jm
  allocate(sdata(mx,my),lmasknoah(mx,my),lmaskgfs(mx,my),vtype(mx,my),tmpsfc(mx,my))
  allocate(cmc(mx,my),sneqv(mx,my),snowh(mx,my),ch(mx,my))
  allocate(smc(mx,my,4),stc(mx,my,4),slc(mx,my,4))

  open(12,file='fort.12',form='unformatted',access='stream',status='unknown')

  allocate(head1(tlmeta/4))

  read(12) head1

  n=1
   do while (n<=nrec)
     varname=sweep_blanks(trim(recname(n))//trim(reclevtyp(n)))

     if(trim(varname)=='tmpsfc') then
       itmp=n
          print*,n,trim(varname),' GLDAS SKNT'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,tmpsfc)
          n=n+1
     elseif(trim(varname)=='cnwatsfc') then
       icmc=n
          print*,n,trim(varname),' GLDAS CMC'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,cmc)
          cmc=cmc*0.001
          n=n+1
     elseif(trim(varname)=='weasdsfc') then
       iswe=n
          print*,n,trim(varname),' GLDAS SWE'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,sneqv)
          sneqv=sneqv*0.001
          n=n+1
     elseif(trim(varname)=='snodsfc') then
       isnd=n
          print*,n,trim(varname),' GLDAS SNOD'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,snowh)
          snowh=snowh*0.001
          n=n+1
       elseif(trim(varname)=='soilw0_10cmdown') then
       ismc=n
          print*,n,trim(varname),' GLDAS SMC1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,smc(:,:,1))
          n=n+1
     elseif(trim(varname)=='soilw10_40cmdown') then
       ismc=n
          print*,n,trim(varname),' GLDAS SMC2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,smc(:,:,2))
          n=n+1
       elseif(trim(varname)=='soilw40_100cmdown') then
       ismc=n
          print*,n,trim(varname),' GLDAS SMC3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,smc(:,:,3))
          n=n+1
     elseif(trim(varname)=='soilw100_200cmdown') then
       ismc=n
          print*,n,trim(varname),' GLDAS SMC4'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,smc(:,:,4))
          n=n+1
      elseif(trim(varname)=='soill0_10cmdown') then
       islc=n
          print*,n,trim(varname),' GLDAS SLC1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,slc(:,:,1))
          n=n+1
     elseif(trim(varname)=='soill10_40cmdown') then
       islc=n
          print*,n,trim(varname),' GLDAS SLC2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,slc(:,:,2))
          n=n+1
      elseif(trim(varname)=='soill40_100cmdown') then
       islc=n
          print*,n,trim(varname),' GLDAS SLC3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,slc(:,:,3))
          n=n+1
     elseif(trim(varname)=='soill100_200cmdown') then
       islc=n
          print*,n,trim(varname),' GLDAS SLC4'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,slc(:,:,4))
          n=n+1
      elseif(trim(varname)=='tmp0_10cmdown') then
       istc=n
          print*,n,trim(varname),' GLDAS STC1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,stc(:,:,1))
          n=n+1
      elseif(trim(varname)=='tmp10_40cmdown') then
       istc=n
          print*,n,trim(varname),' GLDAS STC2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,stc(:,:,2))
          n=n+1
      elseif(trim(varname)=='tmp40_100cmdown') then
       istc=n
          print*,n,trim(varname),' GLDAS STC3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,stc(:,:,3))
          n=n+1
      elseif(trim(varname)=='tmp100_200cmdown') then
       istc=n
          print*,n,trim(varname),' GLDAS STC4'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,stc(:,:,4))
          n=n+1
      elseif(trim(varname)=='landsfc') then
          print*,n,trim(varname)
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,lmaskgfs)
          n=n+1
     elseif(trim(varname)=='vtypesfc') then
          print*,n,trim(varname)
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(mx,my,sdata,vtype)
          n=n+1
     else
        !  print*,n,trim(varname)
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          n=n+1
     endif
   enddo

   close(12)

!---------------------------------------------------------------------------
!*** assign noah values to gldas land points and write to noah.rst
!---------------------------------------------------------------------------

  open(11,file='fort.11',form='unformatted',status='unknown')

  read(11) lmasknoah
  read(11) lmasknoah
  read(11) lmasknoah

  close(11)

  lmasknoah=lmaskgfs

   do j = 1, my
   do i = 1, mx
      if ( lmasknoah(i,j) > 1.0 ) lmasknoah(i,j) = 0.
   enddo
   enddo

   nch = 0
   do j = 1, my
   do i = 1, mx
      if ( lmasknoah(i,j) == 1.0 ) nch = nch + 1
   enddo
   enddo
   allocate(noah(nch))

   open(60,file="noah.rst",form='unformatted')
   write(60) vclass, mx, my, nch
   write(*,*) vclass, mx, my, nch

   call grid2tile(tmpsfc,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(cmc,   lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(snowh, lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(sneqv, lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(stc(:,:,1),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(stc(:,:,2),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(stc(:,:,3),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(stc(:,:,4),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(smc(:,:,1),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(smc(:,:,2),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(smc(:,:,3),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(smc(:,:,4),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(slc(:,:,1),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(slc(:,:,2),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(slc(:,:,3),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(slc(:,:,4),lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(ch,lmasknoah,mx,my,noah,nch)
    write(60) noah
    write(60) noah

   close(60)

!---------------------------------------------------------------------------
!****** clean up
!---------------------------------------------------------------------------
  deallocate(recname,reclevtyp,reclev,lat,slat,dx,head1,noah)
  deallocate(sdata,lmasknoah,lmaskgfs,vtype,tmpsfc)
  deallocate(cmc,sneqv,snowh,ch)
  deallocate(smc,stc,slc)

!---------------------------------------------------------------------------
!
! - - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --
  stop

 end program
! - - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --

 character(35) function sweep_blanks(in_str)
!
   implicit none
!
   character(*), intent(in) :: in_str
   character(35) :: out_str
   character :: ch
   integer :: j

   out_str = " "
   do j=1, len_trim(in_str)
     ! get j-th char
     ch = in_str(j:j)
     if (ch .eq. "-") then
       out_str = trim(out_str) // "_"
     else if (ch .ne. " ") then
       out_str = trim(out_str) // ch
     endif
     sweep_blanks = out_str
   end do
 end function sweep_blanks

!---------------------------------------------------------------------------

  subroutine yrev(mx,my,b,p)

  integer :: mx 
  integer :: my 

  real b(mx,my)
  real p(mx,my)

  do j=1,my
     jj=my-j+1
  do i=1,mx
     p(i,j)=b(i,jj)
     if(p(i,j) .lt. 0.) p(i,j)=1.0
  end do
  end do

  return
  end subroutine yrev

!---------------------------------------------------------------------------

  subroutine grid2tile(grid,lmask,mx,my,tile,nch)

  integer mx
  integer my
  real grid(mx,my)
  real lmask(mx,my)

  integer nch
  real tile(nch)

      k = 0
      do j = 1, my
      do i = 1, mx
!         if( lmask(i,j).gt.0. ) then
         if( lmask(i,j) == 1.0 ) then
           k = k + 1
           tile(k) = grid(i,j)
           if(tile(k) .lt. 0.) tile(k)=tile(k-1)
         endif
      enddo
      enddo

  return
  end subroutine grid2tile

