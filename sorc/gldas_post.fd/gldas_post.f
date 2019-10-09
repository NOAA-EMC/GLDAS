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

  integer, parameter :: mx = 3072
  integer, parameter :: my = 1536
  real mxmy
  real sdata(mx,my)
  real land(mx,my)
  real vtype(mx,my)
  real tmpsfc(mx,my)
  real sneqv(mx,my)
  real snowh(mx,my)
  real smc(mx,my,4)
  real stc(mx,my,4)
  real slc(mx,my,4)
  real cmc(mx,my)
  real, allocatable  :: head1(:)
  
  real smcmax
  real undef(mx,my)

  smcmax = 0.468
!  undef = 9.99E+20
  undef = -9999.
!--------------------------------------------------------------------------
!***  read gldas.gbin
!---------------------------------------------------------------------------
  
  open(11,file='fort.11',form='unformatted',status='unknown')

  read(11) sdata 
  call yrev(sdata,tmpsfc)
  read(11) sdata 
  call yrev(sdata,sneqv)
  read(11) sdata
  call yrev(sdata,smc(:,:,1))
  read(11) sdata
  call yrev(sdata,smc(:,:,2))
  read(11) sdata
  call yrev(sdata,smc(:,:,3))
  read(11) sdata
  call yrev(sdata,smc(:,:,4))
  read(11) sdata
  call yrev(sdata,stc(:,:,1))
  read(11) sdata
  call yrev(sdata,stc(:,:,2))
  read(11) sdata
  call yrev(sdata,stc(:,:,3))
  read(11) sdata
  call yrev(sdata,stc(:,:,4))
  read(11) sdata 
  call yrev(sdata,snowh)
  snowh = snowh * 1000.
  read(11) sdata
  call yrev(sdata,slc(:,:,1))
  read(11) sdata
  call yrev(sdata,slc(:,:,2))
  read(11) sdata
  call yrev(sdata,slc(:,:,3))
  read(11) sdata
  call yrev(sdata,slc(:,:,4))
  read(11) sdata
  call yrev(sdata,cmc)

  close(11)

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
     if(trim(varname)=='smcsoillayer') then
       do k=1,4
       !   print*,n,'GLDAS SMC'
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(smc(:,:,k) < 0.) smc(:,:,k)=sdata 
          write(22) smc(:,:,k)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
       end do
     elseif(trim(varname)=='slcsoillayer') then
       do k=1,4
       !   print*,n,'GLDAS SLC'
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(slc(:,:,k) < 0.) slc(:,:,k)=sdata
          write(22) slc(:,:,k)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
       end do
     elseif(trim(varname)=='stcsoillayer') then
       do k=1,4
       !   print*,n,'GLDAS STC'
          read(12)  mxmy
          write(22) mxmy
          read(12)  sdata
          where(stc(:,:,k) < 0.) stc(:,:,k)=sdata
          write(22) stc(:,:,k)
          read(12)  mxmy
          write(22) mxmy
          n=n+1
       end do
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

  subroutine yrev(b,p)

  integer, parameter :: mx = 3072
  integer, parameter :: my = 1536

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

