!---- - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --
! This program creats T1534 GLDAS fix and noahrst from GFS sfcanl.nemsio
!
! input
!  fort.12 gfs.sfcanl.nemsio
!  fort.11 lmask_gfs_T1534.bfsa
!
! output
!  noah.rst
!
! 20190509 original code by Jesse Meng
! 20190924 revised by Youlong Xia
!-- - - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --
!
  use nemsio_module
  implicit none
!
!---------------------------------------------------------------------------
  integer narg,iargc
!---------------------------------------------------------------------------
  type(nemsio_gfile) :: gfile
  character(255) cin
  real,allocatable  :: data(:,:)
!---------------------------------------------------------------------------
!--- nemsio meta data
  integer nrec,im,jm,lm,idate(7),nfhour,tlmeta,nsoil,fieldsize
  real,allocatable       :: slat(:), dx(:)
  real,allocatable       :: lat(:), lon(:)
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

  integer, parameter :: mx = 3072
  integer, parameter :: my = 1536
  real mxmy
  real sdata(mx,my), sdata1(mx,my)
  real lmasknoah(mx,my)
  real lmaskgfs(mx,my)
  real vtype(mx,my)
  real tsurf(mx,my)
  real canopy(mx,my)
  real weasd(mx,my)
  real snwdph(mx,my)
  real smc(mx,my,4)
  real stc(mx,my,4)
  real slc(mx,my,4)
  real chxy(mx,my)
  real cmxy(mx,my)
  real zorl(mx,my)
  real srflag(mx,my)

  real tprcp(mx,my)
  real trans(mx,my)
  real snowxy(mx,my)
  real tvxy(mx,my)
  real tgxy(mx,my)
  real canicexy(mx,my)
  real canliqxy(mx,my)
  real eahxy(mx,my)
  real tahxy(mx,my)
  real fwetxy(mx,my)
  real sneqvoxy(mx,my)
  real alboldxy(mx,my)
  real qsnowxy(mx,my)
  real wslakexy(mx,my)
  real zwtxy(mx,my)
  real waxy(mx,my)
  real wtxy(mx,my)
  real tsnoxy(mx,my,3)
  real zsnsoxy(mx,my,7)
  real snicexy(mx,my,3)
  real snliqxy(mx,my,3)
  real lfmassxy(mx,my) 
  real rtmassxy(mx,my)
  real stmassxy(mx,my)
  real woodxy(mx,my)
  real stblcpxy(mx,my)
  real fastcpxy(mx,my)
  real xlaixy(mx,my)
  real xsaixy(mx,my)
  real taussxy(mx,my)
  real smoiseq(mx,my,4)
  real smcwtdxy(mx,my)
  real deeprechxy(mx,my)
  real rechxy(mx,my)

  real, allocatable  :: head1(:)

  integer vclass  
  integer nch
  real, allocatable  :: noah(:)

  real undef(mx,my)

  undef = -999.

  vclass = 1
  trans=200.0

!--------------------------------------------------------------------------
!***  read noah lmask
!---------------------------------------------------------------------------

  open(11,file='fort.11',form='unformatted',status='unknown')

  read(11) lmasknoah
  read(11) lmasknoah
  read(11) lmasknoah

  close(11)

  nch = 0
  do j = 1, my
  do i = 1, mx
     if ( lmasknoah(i,j) == 1.0 ) nch = nch + 1
  enddo
  enddo
  allocate(noah(nch))
  
!---------------------------------------------------------------------------
!
  narg=iargc()
  if(narg.lt.1) then
     call errmsg('Usage: LIS_fix.nemsio gdas.sfcanl.nemsio')
     call errexit(1)
  endif

  call nemsio_init(iret=iret)
  if(iret/=0) print *,'ERROR: nemsio_init '
!
!---------------------------------------------------------------------------
!***  read gdas.t00z.sfcanl.nemsio
!---------------------------------------------------------------------------
!--- open sfnanl file for reading
!  
  call getarg(1,cin)
!  cin='fort.12'
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
   allocate(lat(fieldsize),lon(fieldsize),slat(jm),dx(fieldsize))
   call nemsio_getfilehead(gfile,iret=iret,recname=recname,          &
       reclevtyp=reclevtyp,reclev=reclev,lat=lat,lon=lon)
!
  call nemsio_close(gfile,iret=iret)
!
  call nemsio_finalize()
!
!---------------------------------------------------------------------------
!*** read sfnanl.nemsio
!---------------------------------------------------------------------------
!
  open(12,file=cin,form='unformatted',access='stream',status='unknown')

  allocate(head1(tlmeta/4))

  read(12) head1

  n=1
   do while (n<=nrec)
     varname=sweep_blanks(trim(recname(n))//trim(reclevtyp(n)))

     if(trim(varname)=='tmpsfc') then
       itmp=n
          print*,n,trim(varname),' GLDAS tsurf'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,tsurf)
          n=n+1
     elseif(trim(varname)=='cnwatsfc') then
       icmc=n
          print*,n,trim(varname),' GLDAS canopy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,canopy)  ! mm
          n=n+1
     elseif(trim(varname)=='weasdsfc') then
       iswe=n
          print*,n,trim(varname),' GLDAS SWE'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,weasd)  ! mm
          n=n+1
     elseif(trim(varname)=='snodsfc') then
       isnd=n
          print*,n,trim(varname),' GLDAS SNOD'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,snwdph)    ! mm
          n=n+1
     elseif(trim(varname)=='soilw0_10cmdown') then
       ismc=n
          print*,n,trim(varname),' GLDAS SMC1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,smc(:,:,1))          
          n=n+1
     elseif(trim(varname)=='soilw10_40cmdown') then
       ismc=n
          print*,n,trim(varname),' GLDAS SMC2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,smc(:,:,2))
          n=n+1
     elseif(trim(varname)=='soilw40_100cmdown') then
       ismc=n
          print*,n,trim(varname),' GLDAS SMC3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,smc(:,:,3))
          n=n+1
     elseif(trim(varname)=='soilw100_200cmdown') then
       ismc=n
          print*,n,trim(varname),' GLDAS SMC4'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,smc(:,:,4))
          n=n+1
     elseif(trim(varname)=='soill0_10cmdown') then
       islc=n      
          print*,n,trim(varname),' GLDAS SLC1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,slc(:,:,1))
          n=n+1
     elseif(trim(varname)=='soill10_40cmdown') then
       islc=n
          print*,n,trim(varname),' GLDAS SLC2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,slc(:,:,2))
          n=n+1
     elseif(trim(varname)=='soill40_100cmdown') then
       islc=n
          print*,n,trim(varname),' GLDAS SLC3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,slc(:,:,3))
          n=n+1
     elseif(trim(varname)=='soill100_200cmdown') then
       islc=n
          print*,n,trim(varname),' GLDAS SLC4'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,slc(:,:,4))
          n=n+1
     elseif(trim(varname)=='tmp0_10cmdown') then
       istc=n
          print*,n,trim(varname),' GLDAS STC1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,stc(:,:,1))
          n=n+1
      elseif(trim(varname)=='tmp10_40cmdown') then
       istc=n
          print*,n,trim(varname),' GLDAS STC2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,stc(:,:,2))
          n=n+1
      elseif(trim(varname)=='tmp40_100cmdown') then
       istc=n
          print*,n,trim(varname),' GLDAS STC3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,stc(:,:,3))
          n=n+1
      elseif(trim(varname)=='tmp100_200cmdown') then
       istc=n
          print*,n,trim(varname),' GLDAS STC4'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,stc(:,:,4))
          n=n+1
      elseif(trim(varname)=='chxysfc') then
          print*,n,trim(varname),' GLDAS chxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,chxy)  
          n=n+1
     elseif(trim(varname)=='cmxysfc') then
          print*,n,trim(varname),' GLDAS cmxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,cmxy)
          n=n+1
     elseif(trim(varname)=='sfcrsfc') then
          print*,n,trim(varname),' GLDAS zorl'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,zorl)
          n=n+1
     elseif(trim(varname)=='tprcpsfc') then
          print*,n,trim(varname),' GLDAS tprcp'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,tprcp)
          n=n+1
     elseif(trim(varname)=='crainsfc') then
          print*,n,trim(varname),' GLDAS srflag'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,srflag)
          n=n+1
     elseif(trim(varname)=='alboldxysfc') then
          print*,n,trim(varname),' GLDAS alboldxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,alboldxy)
          n=n+1
     elseif(trim(varname)=='sneqvoxysfc') then
          print*,n,trim(varname),' GLDAS sneqvoxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,sneqvoxy)
          n=n+1
     elseif(trim(varname)=='tahxysfc') then
          print*,n,trim(varname),' GLDAS tahxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,tahxy)
          n=n+1
     elseif(trim(varname)=='eahxysfc') then
          print*,n,trim(varname),' GLDAS eahxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,eahxy)
          n=n+1
     elseif(trim(varname)=='fwetxysfc') then
          print*,n,trim(varname),' GLDAS fwetxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,fwetxy)
          n=n+1
    elseif(trim(varname)=='canliqxysfc') then
          print*,n,trim(varname),' GLDAS canliqxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,canliqxy)
          n=n+1
   elseif(trim(varname)=='canicexysfc') then
          print*,n,trim(varname),' GLDAS canicexy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,canicexy)
          n=n+1
    elseif(trim(varname)=='tvxysfc') then
          print*,n,trim(varname),' GLDAS tvxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,tvxy)
          n=n+1
    elseif(trim(varname)=='tgxysfc') then
          print*,n,trim(varname),' GLDAS tgxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,tgxy)
          n=n+1
     elseif(trim(varname)=='qsnowxysfc') then
          print*,n,trim(varname),' GLDAS qsnowxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,qsnowxy)
          n=n+1
     elseif(trim(varname)=='snowxysfc') then
          print*,n,trim(varname),' GLDAS snowxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,snowxy)
          n=n+1
    elseif(trim(varname)=='zwtxysfc') then
          print*,n,trim(varname),' GLDAS zwtxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,zwtxy)
          n=n+1
    elseif(trim(varname)=='waxysfc') then
          print*,n,trim(varname),' GLDAS waxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,waxy)
          n=n+1
    elseif(trim(varname)=='wtxysfc') then
          print*,n,trim(varname),' GLDAS wtxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,wtxy)
          n=n+1
     elseif(trim(varname)=='wslakexysfc') then
          print*,n,trim(varname),' GLDAS wslakexy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,wslakexy)
          n=n+1
     elseif(trim(varname)=='lfmassxysfc') then
          print*,n,trim(varname),' GLDAS lfmassxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,lfmassxy)
          n=n+1
    elseif(trim(varname)=='rtmassxysfc') then
          print*,n,trim(varname),' GLDAS rtmassxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,rtmassxy)
          n=n+1
     elseif(trim(varname)=='stmassxysfc') then
          print*,n,trim(varname),' GLDAS stmassxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,stmassxy)
          n=n+1
     elseif(trim(varname)=='woodxysfc') then
          print*,n,trim(varname),' GLDAS woodxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,woodxy)
          n=n+1
    elseif(trim(varname)=='stblcpxysfc') then
          print*,n,trim(varname),' GLDAS stblcpxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,stblcpxy)
          n=n+1
    elseif(trim(varname)=='fastcpxysfc') then
          print*,n,trim(varname),' GLDAS fastcpxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,fastcpxy)
          n=n+1
    elseif(trim(varname)=='xlaixysfc') then
          print*,n,trim(varname),' GLDAS xlaixy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,xlaixy)
          n=n+1
    elseif(trim(varname)=='xsaixysfc') then
          print*,n,trim(varname),' GLDAS xsaixy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,xsaixy)
          n=n+1
    elseif(trim(varname)=='taussxysfc') then
          print*,n,trim(varname),' GLDAS taussxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,taussxy)
          n=n+1
     elseif(trim(varname)=='smcwtdxysfc') then
          print*,n,trim(varname),' GLDAS smcwtdxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,smcwtdxy)
          n=n+1
     elseif(trim(varname)=='deeprechxysfc') then
          print*,n,trim(varname),' GLDAS deeprechxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,deeprechxy)
          n=n+1
     elseif(trim(varname)=='rechxysfc') then
          print*,n,trim(varname),' GLDAS rechxy'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,rechxy)
          n=n+1
     elseif(trim(varname)=='tsnoxy1sfc') then
          print*,n,trim(varname),' GLDAS tsnoxy1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,tsnoxy(:,:,1))
          n=n+1
      elseif(trim(varname)=='tsnoxy2sfc') then
          print*,n,trim(varname),' GLDAS tsnoxy2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,tsnoxy(:,:,2))
          n=n+1        
      elseif(trim(varname)=='tsnoxy3sfc') then
          print*,n,trim(varname),' GLDAS tsnoxy3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,tsnoxy(:,:,3))
          n=n+1
       elseif(trim(varname)=='zsnsoxy1sfc') then
          print*,n,trim(varname),' GLDAS zsnsoxy1'
          read(12)  mxmy
          read(12)  sdata1
          read(12)  mxmy
          sdata=-1.0*sdata1    
          call yrev(sdata,zsnsoxy(:,:,1))
          n=n+1
     elseif(trim(varname)=='zsnsoxy2sfc') then
          print*,n,trim(varname),' GLDAS zsnsoxy2'
          read(12)  mxmy
          read(12)  sdata1
          read(12)  mxmy
          sdata=-1.0*sdata1
          call yrev(sdata,zsnsoxy(:,:,2))
          n=n+1
      elseif(trim(varname)=='zsnsoxy3sfc') then
          print*,n,trim(varname),' GLDAS zsnsoxy3'
          read(12)  mxmy
          read(12)  sdata1
          read(12)  mxmy
          sdata=-1.0*sdata1
          call yrev(sdata,zsnsoxy(:,:,3))
          n=n+1
     elseif(trim(varname)=='zsnsoxy4sfc') then
          print*,n,trim(varname),' GLDAS zsnsoxy4'
          read(12)  mxmy
          read(12)  sdata1
          read(12)  mxmy
          sdata=-1.0*sdata1
          call yrev(sdata,zsnsoxy(:,:,4))
          n=n+1
     elseif(trim(varname)=='zsnsoxy5sfc') then
          print*,n,trim(varname),' GLDAS zsnsoxy5'
          read(12)  mxmy
          read(12)  sdata1
          read(12)  mxmy
          sdata=-1.0*sdata1
          call yrev(sdata,zsnsoxy(:,:,5))
          n=n+1
     elseif(trim(varname)=='zsnsoxy6sfc') then
          print*,n,trim(varname),' GLDAS zsnsoxy6'
          read(12)  mxmy
          read(12)  sdata1
          read(12)  mxmy
          sdata=-1.0*sdata1
          call yrev(sdata,zsnsoxy(:,:,6))
          n=n+1
     elseif(trim(varname)=='zsnsoxy7sfc') then
          print*,n,trim(varname),' GLDAS zsnsoxy7'
          read(12)  mxmy
          read(12)  sdata1
          read(12)  mxmy
          sdata=-1.0*sdata1
          call yrev(sdata,zsnsoxy(:,:,7))
          n=n+1
    elseif(trim(varname)=='snicexy1sfc') then
          print*,n,trim(varname),' GLDAS snicexy1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,snicexy(:,:,1))
          n=n+1
     elseif(trim(varname)=='snicexy2sfc') then
          print*,n,trim(varname),' GLDAS snicexy2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,snicexy(:,:,2))
          n=n+1
     elseif(trim(varname)=='snicexy3sfc') then
          print*,n,trim(varname),' GLDAS snicexy3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,snicexy(:,:,3))
          n=n+1
     elseif(trim(varname)=='snliqxy1sfc') then
          print*,n,trim(varname),' GLDAS snliqxy1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,snliqxy(:,:,1))
          n=n+1
     elseif(trim(varname)=='snliqxy2sfc') then
          print*,n,trim(varname),' GLDAS snliqxy2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,snliqxy(:,:,2))
          n=n+1
     elseif(trim(varname)=='snliqxy3sfc') then
          print*,n,trim(varname),' GLDAS snliqxy3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,snliqxy(:,:,3))
          n=n+1
     elseif(trim(varname)=='smoiseq1sfc') then
          print*,n,trim(varname),' GLDAS smoiseq1'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,smoiseq(:,:,1))
          n=n+1
     elseif(trim(varname)=='smoiseq2sfc') then
          print*,n,trim(varname),' GLDAS smoiseq2'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,smoiseq(:,:,2))
          n=n+1
     elseif(trim(varname)=='smoiseq3sfc') then
          print*,n,trim(varname),' GLDAS smoiseq3'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,smoiseq(:,:,3))
          n=n+1
     elseif(trim(varname)=='smoiseq4sfc') then
          print*,n,trim(varname),' GLDAS smoiseq4'
          read(12)  mxmy
          read(12)  sdata
          read(12)  mxmy
          call yrev(sdata,smoiseq(:,:,4))
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

   do j=1,my
    do i=1,mx

     if(wslakexy(i,j).gt.5000.0) then
     wslakexy(i,j)=0.0
     endif

     if(taussxy(i,j).ge.1.0) then
     taussxy(i,j)=0.4
     endif

    enddo
   enddo
! -----------------------------------------------------------------------
!*** assign noah values to gldas land points and write to noah.rst
!----------------------------------------------------------------------
   
   open(60,file="noah.rst",form='unformatted')
   write(60) vclass, mx, my, nch

   call grid2tile(tsurf,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(canopy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(snwdph,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(weasd,lmasknoah,mx,my,noah,nch)
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
   call grid2tile(chxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(cmxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(zorl,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(tsurf,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(trans,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(tprcp,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(srflag,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(alboldxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(sneqvoxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(tahxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(eahxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(fwetxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(canliqxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(canicexy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(tvxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(tgxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(qsnowxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(snowxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(zwtxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(waxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
   call grid2tile(wtxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(wslakexy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(lfmassxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(rtmassxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(stmassxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(woodxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(stblcpxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(fastcpxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(xlaixy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(xsaixy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(taussxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(smcwtdxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(deeprechxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(rechxy,lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(tsnoxy(:,:,1),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(tsnoxy(:,:,2),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(tsnoxy(:,:,3),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(zsnsoxy(:,:,1),lmasknoah,mx,my,noah,nch)
    write(60) noah
  write(*,*) noah
  call grid2tile(zsnsoxy(:,:,2),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(zsnsoxy(:,:,3),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(zsnsoxy(:,:,4),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(zsnsoxy(:,:,5),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(zsnsoxy(:,:,6),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(zsnsoxy(:,:,7),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(snicexy(:,:,1),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(snicexy(:,:,2),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(snicexy(:,:,3),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(snliqxy(:,:,1),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(snliqxy(:,:,2),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(snliqxy(:,:,3),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(smoiseq(:,:,1),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(smoiseq(:,:,2),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(smoiseq(:,:,3),lmasknoah,mx,my,noah,nch)
    write(60) noah
  call grid2tile(smoiseq(:,:,4),lmasknoah,mx,my,noah,nch)
    write(60) noah

   close(60)

!---------------------------------------------------------------------------
!****** clean up
!---------------------------------------------------------------------------
  deallocate(recname,reclevtyp,reclev,lat,lon,slat,dx,head1,noah)
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
         if( lmask(i,j) == 1.0 ) then
           k = k + 1
           tile(k) = grid(i,j)
           if(tile(k) .lt. 0.) tile(k)=tile(k-1)
         endif
      enddo
      enddo

  return
  end subroutine grid2tile

