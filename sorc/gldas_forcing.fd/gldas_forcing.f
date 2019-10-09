! ifort xie2014.F -free -L/nwprod/lib/ -lbacio_4 -lw3nco_4
!- - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --
! This program creats 6hr 0.25 deg gldas precip forcing from
! CPC PRCP_CU_GAUGE_V1.0GLB_0.25deg.lnx.20190101.RT
! 6hr disaggregate with GDAS 6 hr precip
!
! input
!  
!   fort.11 gdas.precip.t00z.f06 copygb to 0.25 deg in bin
!   fort.12 gdas.precip.t06z.f06 copygb to 0.25 deg in bin
!   fort.13 gdas.precip.t12z.f06 copygb to 0.25 deg in bin
!   fort.14 gdas.precip.t18z.f06 copygb to 0.25 deg in bin
!   fort.15 PRCP_CU_GAUGE_V1.0GLB_0.25deg in bin
!  
! output
!
!   fort.21 precip.gldas.t00z.f06.grb 0.25 deg
!   fort.22 precip.gldas.t00z.f06.grb 0.25 deg
!   fort.23 precip.gldas.t00z.f06.grb 0.25 deg
!   fort.24 precip.gldas.t00z.f06.grb 0.25 deg
!
! 20190509 Jesse Meng
! - - - - -- - -- - -- - -- - - -- - --  -- - -- - -- - - -- - - - -- - --
!
  implicit none

  integer :: i, j, k, j1, j2
  integer, parameter :: mx = 1440
  integer, parameter :: my = 720
  real               :: data1(mx,my,4)    !N-S
  real               :: data1s(mx,my)     !N-S SUM data1
  real               :: data2(mx,my)      !S-N
  real               :: data2r(mx,my)     !N-S

  integer            :: year
  integer            :: month
  integer            :: day
  integer            :: hour
  integer            :: kpds(200)
  integer            :: kgds(200)
  logical*1          :: bitmap(mx,my)
  integer            :: iret

! GET DATE

  open(10,file='fort.10',status='old')
  read(10,'(I4,I2,I2)') year, month, day
  close(10)
  hour = 0
  print*, year, month, day, hour

! PDS AND GDS

  kpds = 0
      kpds(1) = 7             !NCEP
      kpds(2) = 141           !LDAS
      kpds(3) = 255           !NONDEFINE GRID
      kpds(4) = 192           !GDS+BITMAP
      kpds(5) = 59            !PRATE
      kpds(6) = 1             !SURFACE
      kpds(7) = 0             !LEVEL
      kpds(8) = mod(year,100) !YY
      kpds(9) = month         !MONTH
      kpds(10)= day           !DAY
      kpds(11)= hour          !HOUR
      kpds(12)= 0             !MINUTE
      kpds(13)= 1             !FORECAST TIME UNIT
      kpds(14)= 0             !P1
      kpds(15)= 6             !P2
      kpds(16)= 3             !AVE (P1-P2)
      kpds(17)= 0             !NUMBER INCLUDED IN AVE
      kpds(18)= 0             !NOT USED
      kpds(19)= 130           !LDAS PARAMETER TABLE
      kpds(20)= 0             !MISSING
      kpds(21)= year/100 + 1  !CENTURY
      kpds(22)= 6             !DECIMAL
      kpds(23)= 4             !EMC
      kpds(24)= 0             !NOT USED
      kpds(25)= 0             !NOT USED

  kgds = 0
      kgds(1) = 0
      kgds(2) = mx
      kgds(3) = my
      kgds(4) =   89875
      kgds(5) =     125
      kgds(6) = 128
      kgds(7) =  -89875
      kgds(8) =  359875
      kgds(9) =     250
      kgds(10)=     250
      kgds(11)= 0
      kgds(12)= 0
      kgds(13)= 0
      kgds(14)= 0
      kgds(15)= 0
      kgds(16)= 0
      kgds(17)= 0
      kgds(18)= 0
      kgds(19)= 0
      kgds(20)= 255
      kgds(21)= 0
      kgds(22)= 0
      kgds(23)= 0
      kgds(24)= 0
      kgds(25)= 0

  print*, kpds(1:25)
  print*, kgds(1:25)

! GET 6 HR CFSR PRECIP.GLDAS

  open (11,file='fort.11',form='unformatted')
  read (11) data1(:,:,1)
  close(11)
  open (12,file='fort.12',form='unformatted')
  read (12) data1(:,:,2)
  close(12)
  open (13,file='fort.13',form='unformatted')
  read (13) data1(:,:,3)
  close(13)
  open (14,file='fort.14',form='unformatted')
  read (14) data1(:,:,4)
  close(14)

! SUM TO DAILY

  do j = 1, my
  do i = 1, mx
     if(data1(i,j,1) .GE. 0.) then
        data1s(i,j)=data1(i,j,1)+data1(i,j,2)+data1(i,j,3)+data1(i,j,4)
        data1s(i,j)=data1s(i,j)*21600.
     else
        data1s=-999.
     endif
  enddo
  enddo

! GET XIE PRECIP

  open (15,file='fort.15',form='unformatted',&
          access='direct',recl=mx*my, status='old')
!          access='direct',recl=mx*my*4, status='old')
  read (15,rec=1) data2
  close(15)

  data2=data2/10.

! YREV
  
  j2 = 1
  do j1 = my, 1, -1
     data2r(:,j2) = data2(:,j1)
     j2 = j2 + 1
  enddo

! DISAGGREGATE

  do k = 1, 4
  do j = 1, my
  do i = 1, mx
     if ( data2r(i,j) .GT. 0. ) then
        if ( data1s(i,j) .GT. 0. ) then
           data1(i,j,k) = data1(i,j,k) / data1s(i,j) * data2r(i,j)
        else
           data1(i,j,k) = data2r(i,j) / 86400.
        endif
     else
        data1(i,j,k) = data2r(i,j)
     endif
  enddo
  enddo
  enddo
  
!  write(51) data1(:,:,1)
!  write(52) data1(:,:,2)
!  write(53) data1(:,:,3)
!  write(54) data1(:,:,4)

! GRIBOUT

  kpds(11) = 0

  bitmap = .TRUE.
  where ( data1(:,:,1) .LT. 0. )
    bitmap = .FALSE.
  end where

  print*, 'fort.21', kpds(11)
  iret = 0
  call baopen(21,'fort.21',iret)
  print*, 'iret =', iret
  iret = 0
  call putgb(21,mx*my,kpds,kgds,bitmap,data1(:,:,1),iret)
  print*, 'iret =', iret
  iret = 0
  call baclose(21, iret)
  print*, 'iret =', iret
  print*

  kpds(11) = 6

  bitmap = .TRUE.
  where ( data1(:,:,2) .LT. 0. )
    bitmap = .FALSE.
  end where

  print*, 'fort.22', kpds(11)
  iret = 0
  call baopen(22,'fort.22',iret)
  print*, 'iret =', iret
  iret = 0
  call putgb(22,mx*my,kpds,kgds,bitmap,data1(:,:,2),iret)
  print*, 'iret =', iret
  iret = 0
  call baclose(22, iret)
  print*, 'iret =', iret
  print*

  kpds(11) = 12

  bitmap = .TRUE.
  where ( data1(:,:,3) .LT. 0. )
    bitmap = .FALSE.
  end where

  print*, 'fort.23', kpds(11)
  iret = 0
  call baopen(23,'fort.23',iret)
  print*, 'iret =', iret
  iret = 0
  call putgb(23,mx*my,kpds,kgds,bitmap,data1(:,:,3),iret)
  print*, 'iret =', iret
  iret = 0
  call baclose(23, iret)
  print*, 'iret =', iret
  print*

  kpds(11) = 18

  bitmap = .TRUE.
  where ( data1(:,:,4) .LT. 0. )
    bitmap = .FALSE.
  end where

  print*, 'fort.24', kpds(11)
  iret = 0
  call baopen(24,'fort.24',iret)
  print*, 'iret =', iret
  iret = 0
  call putgb(24,mx*my,kpds,kgds,bitmap,data1(:,:,4),iret)
  print*, 'iret =', iret
  iret = 0
  call baclose(24, iret)
  print*, 'iret =', iret
  print*

  stop
  end
