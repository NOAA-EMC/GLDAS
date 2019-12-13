!- - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --
! This program creats T1534 GDAS GLDAS sfcanl file sfcanl.nemsio.gldas 
! with blending GDAS and GLDAS FIELDS
!
! input
!  fort.11 gldas.gbin    - gldas binary output
!  fort.12 sfcanl.nemsio - gfs sfcanl file
!
! output
!  fort.22 sfcanl.nemsio.gldas - gfs sfcanl with gldas fields
!
! 20190509 Jesse Meng
! - - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --
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
  integer ismc, islc, istc
  character*3 var3(3)
  integer idx3(3)

  integer mx
  integer my
  real mxmy
  real, allocatable :: sdata(:,:)
  real, allocatable :: land(:,:)
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
  
  real smcmax
  real,allocatable :: undef(:,:)

  smcmax = 0.468
!  undef = 9.99E+20
!  undef = -9999.

!---------------------------------------------------------------------------
!
  call nemsio_init(iret=iret)
  if(iret/=0) print *,'ERROR: nemsio_init '
!
!---------------------------------------------------------------------------
!***  read nemsio grd header info
!---------------------------------------------------------------------------
!--- open gfile for reading
  
  cin='fort.12'

  call nemsio_open(gfile,trim(cin),'READ',iret=iret)
  if(iret/=0) print *,'Error: open nemsio file,',trim(cin),' iret=',iret

  call nemsio_getfilehead(gfile,iret=iret,nrec=nrec,dimx=im,dimy=jm, &
    dimz=lm,idate=idate,nfhour=nfhour,                               &
    nsoil=nsoil,tlmeta=tlmeta)
  print* , im, jm, lm, tlmeta
!
   fieldsize=im*jm
   allocate(recname(nrec),reclevtyp(nrec),reclev(nrec))
   allocate(lat(fieldsize),slat(jm),dx(fieldsize))
   allocate(sdata(im,jm),land(im,jm),vtype(im,jm))
   call nemsio_getfilehead(gfile,iret=iret,recname=recname,          &
       reclevtyp=reclevtyp,reclev=reclev)
!
  call nemsio_close(gfile,iret=iret)
!
  call nemsio_finalize()
!
!---------------------------------------------------------------------------
!****** get vtype from sfnanl.fix for qc
!---------------------------------------------------------------------------
!
  open(12,file='fort.12',form='unformatted',access='stream',status='unknown')

  allocate(head1(tlmeta/4))

  read(12) head1

  n=1
   do while (n<=nrec)
     varname=sweep_blanks(trim(recname(n))//trim(reclevtyp(n)))
     read(12)  mxmy
     read(12)  sdata
     read(12)  mxmy
     if(trim(varname)=='landsfc') then
          print*,n,' got landsfc from sfnanl'
          land  = sdata
     endif
     if(trim(varname)=='vtypesfc') then
          print*,n,' got vtypesfc from sfnanl'
          vtype = sdata
     endif
     n=n+1
   end do
  close(12)
  deallocate(head1)

!--------------------------------------------------------------------------
!***  read gldas.gbin
!---------------------------------------------------------------------------

  mx=im
  my=jm
  allocate(lmaskgfs(mx,my),tmpsfc(mx,my))
  allocate(cmc(mx,my),sneqv(mx,my),snowh(mx,my),ch(mx,my),undef(mx,my))
  allocate(smc(mx,my,4),stc(mx,my,4),slc(mx,my,4))
  undef=-9999.

  open(11,file='fort.11',form='unformatted',status='unknown')

  read(11) sdata
  call yrev(mx,my,sdata,tmpsfc)
  read(11) sdata
  call yrev(mx,my,sdata,sneqv)
  sneqv = sneqv * 1000.
  read(11) sdata
  call yrev(mx,my,sdata,smc(:,:,1))
  read(11) sdata
  call yrev(mx,my,sdata,smc(:,:,2))
  read(11) sdata
  call yrev(mx,my,sdata,smc(:,:,3))
  read(11) sdata
  call yrev(mx,my,sdata,smc(:,:,4))
  read(11) sdata
  call yrev(mx,my,sdata,stc(:,:,1))
  read(11) sdata
  call yrev(mx,my,sdata,stc(:,:,2))
  read(11) sdata
  call yrev(mx,my,sdata,stc(:,:,3))
  read(11) sdata
  call yrev(mx,my,sdata,stc(:,:,4))
  read(11) sdata
  call yrev(mx,my,sdata,snowh)
  snowh = snowh * 1000.
  read(11) sdata
  call yrev(mx,my,sdata,slc(:,:,1))
  read(11) sdata
  call yrev(mx,my,sdata,slc(:,:,2))
  read(11) sdata
  call yrev(mx,my,sdata,slc(:,:,3))
  read(11) sdata
  call yrev(mx,my,sdata,slc(:,:,4))
  read(11) sdata
  call yrev(mx,my,sdata,cmc)

  close(11)

  do k=1,4
  do j=1,my
  do i=1,mx
     if(land(i,j)  .ne. 1.0) then
        smc(i,j,k) = undef(i,j)
        slc(i,j,k) = undef(i,j)
        stc(i,j,k) = undef(i,j)
        sneqv(i,j) = undef(i,j)
        snowh(i,j) = undef(i,j)
     endif
     if(vtype(i,j) .le. 0.0) then
        smc(i,j,k) = 1.0
        slc(i,j,k) = 1.0
        stc(i,j,k) = undef(i,j)
        sneqv(i,j) = undef(i,j)
        snowh(i,j) = undef(i,j)
     elseif(vtype(i,j) .eq. 15.) then !15=glacial
        smc(i,j,k) = 1.0
        slc(i,j,k) = 1.0
        stc(i,j,k) = undef(i,j)
        sneqv(i,j) = undef(i,j)
        snowh(i,j) = undef(i,j)
     elseif(vtype(i,j) .eq. 17.) then !17=water
        smc(i,j,k) = 1.0
        slc(i,j,k) = 1.0
        stc(i,j,k) = undef(i,j)
        sneqv(i,j) = undef(i,j)
        snowh(i,j) = undef(i,j)
     else
     !qc for non water land point
     if(smc(i,j,k) .gt. smcmax) then
        smc(i,j,k) = undef(i,j)
        slc(i,j,k) = undef(i,j)
        stc(i,j,k) = undef(i,j)
     endif
     endif

     if(slc(i,j,k) .gt. smc(i,j,k)) then
        slc(i,j,k) = smc(i,j,k)
     endif
   end do
   end do
   end do

!---------------------------------------------------------------------------
!****** write sfnanl.gldas
!---------------------------------------------------------------------------
!
  open(12,file='fort.12',form='unformatted',access='stream',status='unknown')

  allocate(head1(tlmeta/4))

  read(12) head1

! create sfnanl.gldas
! write header

  open(22,file='fort.22',form='unformatted',access='stream',status='unknown')

  write(22) head1

  n=1
   do while (n<=nrec)
     varname=sweep_blanks(trim(recname(n))//trim(reclevtyp(n)))
     if(trim(varname)=='soilw0_10cmdown') then
       !   print*,n,'GLDAS SMC1'
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(smc(:,:,1) < 0.) smc(:,:,1)=sdata 
          write(22) smc(:,:,1)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
     elseif(trim(varname)=='soilw10_40cmdown') then   
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(smc(:,:,2) < 0.) smc(:,:,2)=sdata
          write(22) smc(:,:,2)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
      elseif(trim(varname)=='soilw40_100cmdown') then
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(smc(:,:,3) < 0.) smc(:,:,3)=sdata
          write(22) smc(:,:,3)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
       elseif(trim(varname)=='soilw100_200cmdown') then
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(smc(:,:,4) < 0.) smc(:,:,4)=sdata
          write(22) smc(:,:,4)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
     elseif(trim(varname)=='soill0_10cmdown') then
       !   print*,n,'GLDAS SLC'
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(slc(:,:,1) < 0.) slc(:,:,1)=sdata
          write(22) slc(:,:,1)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
      elseif(trim(varname)=='soill10_40cmdown') then           
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(slc(:,:,2) < 0.) slc(:,:,2)=sdata
          write(22) slc(:,:,2)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
       elseif(trim(varname)=='soill40_100cmdown') then
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(slc(:,:,3) < 0.) slc(:,:,3)=sdata
          write(22) slc(:,:,3)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
        elseif(trim(varname)=='soill100_200cmdown') then
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(slc(:,:,4) < 0.) slc(:,:,4)=sdata
          write(22) slc(:,:,4)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
     elseif(trim(varname)=='tmp0_10cmdown') then
       !   print*,n,'GLDAS STC'
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(stc(:,:,1) < 0.) stc(:,:,1)=sdata
          write(22) stc(:,:,1)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
     elseif(trim(varname)=='tmp10_40cmdown') then
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(stc(:,:,2) < 0.) stc(:,:,2)=sdata
          write(22) stc(:,:,2)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
      elseif(trim(varname)=='tmp40_100cmdown') then
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(stc(:,:,3) < 0.) stc(:,:,3)=sdata
          write(22) stc(:,:,3)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
       elseif(trim(varname)=='tmp100_200cmdown') then 
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(stc(:,:,4) < 0.) stc(:,:,4)=sdata
          write(22) stc(:,:,4)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
     elseif(trim(varname)=='snodsfc') then
       !   print*,n,'GLDAS SNOWH'
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(snowh < 0.) snowh=sdata
          write(22) snowh
          read(12)  mxmy
          write(22) mxmy
          n=n+1
     elseif(trim(varname)=='weasdsfc') then
       !   print*,n,'GLDAS SNEQV'
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(sneqv < 0.) sneqv=sdata
          write(22) sneqv
          read(12)  mxmy
          write(22) mxmy
          n=n+1
     else
       !   print*,n,trim(varname)
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          write(22) sdata
          read(12)  mxmy
          write(22) mxmy
          n=n+1
     endif
   enddo

   close(12)
   close(22)

!---------------------------------------------------------------------------
!****** clean up
!---------------------------------------------------------------------------
  deallocate(recname,reclevtyp,reclev,lat,slat,dx,head1)
  deallocate(sdata,land,lmaskgfs,vtype,tmpsfc)
  deallocate(cmc,sneqv,snowh,ch,undef)
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

!  integer, parameter :: mx = 3072
!  integer, parameter :: my = 1536
  integer :: mx
  integer :: my

  real b(mx,my)
  real p(mx,my)

  do j=1,my
     jj=my-j+1
  do i=1,mx
     p(i,j)=b(i,jj)
  end do
  end do

  return
  end

