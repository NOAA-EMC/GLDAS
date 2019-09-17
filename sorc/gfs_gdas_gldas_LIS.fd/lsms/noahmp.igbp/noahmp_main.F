! JESSE 20130711 IGBP STASGO
! JESSE 20070501 ADD FORCING ZLEV, Z0, CH, T1
! JESSE 20050406 FIX SNCOVR, ALBEDO
! JESSE 20050523 FIX ICE
!-------------------------------------------------------------------------
!     NASA GSFC Land Information Systems LIS 2.3                         !
!-------------------------------------------------------------------------
!BOP
!
! !ROUTINE: noah_main.F90
! 
! NOAH LAND-SURFACE MODEL, UNCOUPLED 1-D COLUMN: VERSION 2.5 OCT 2001
!
! THIS MAIN PROGRAM AND ITS FAMILY OF SUBROUTINES COMPRISE VERSION 2.5
! OF THE PUBLIC RELEASE OF THE UNCOUPLED 1-D COLUMN VERSION OF THE
! "NOAH" LAND-SURFACE MODEL (LSM). THE NOAH LSM IS A DESCENDANT OF AN
! EARLIER GENERATION OF THE OREGON STATE UNIVERSITY (OSU) LSM, BUT IT
! INCLUDES SUBSTANTIAL PHYSICS EXTENSIONS AND RECODING ACCOMPLISHED
! ALONG THE WAY BY NCEP, HL (NWS), AFGWC, AND AFGL/AFPL/AFRL.  HENCE
! THE ACRONYM "NOAH" DENOTES N-NCEP, O-OSU, A-AIR FORCE, H-HYDRO LAB.
! ----------------------------------------------------------------------
! FOR DOCUMENTATION OF THIS CODE AND INSTRUCTIONS ON ITS EXECUTION AND
! INPUT/OUTPUT FILES, SEE "NOAH LSM USERS GUIDE" IN FILE README$_-$2.5
! IN THE SAME PUBLIC SERVER DIRECTORY AS THIS SOURCE CODE.
! ----------------------------------------------------------------------
! PROGRAM HISTORY LOG
! VERSION 1.0  --  01 MAR 1999\\
! VERSION 1.1  --  08 MAR 1999\\
! VERSION 2.0  --  27 JUL 1999\\
! VERSION 2.1  --  23 OCT 2000\\
! VERSION 2.2  --  07 FEB 2001\\
! VERSION 2.3  --  07 MAY 2001 = operational Eta implementation\\
! VERSION 2.4  --  27 JUN 2001 = ops Eta with NO physics changes\\
! VERSION 2.5  --  18 OCT 2001\\
! LDAS VERSION --  28 APR 2002 = NOAH Main added to LDAS Driver\\
!                                (NASA GSFC)\\
! VERSION 2.5.1--  28 MAY 2002 = Updated changes in NOAH LSM along\\
!                                with correction to SOILRZ and SOIL1M.\\  
! VERSION 2.6  --  24 JUN 2003 = Updated to Noah LSM v2.6 \\
!
!   Physics changes:\\
!     in SUBROUTINE SFLX change CSOIL from 1.26E+6 to 2.00E+6\\
!     in SUBROUTINE SFLX change ZBOT from -3.0 to -8.0\\
!     Replaced de-bugged SUBROUTINE TDFCND\\
!     Removed SUBROUTINE REDPRM and moved the parameters to other\\
!      locations throughout noah$_-$main and noah$_-$physics subroutines.\\ 
!    VERSION 2.5.2 --  31 MAY 2002\\
!      Fix in FUNCTION DEVAP related to FX calculation\\
!    VERSION 2.6   --  Includes changes to certain parameters and\\
!                     snow-soil physics\\
! revised for noahmp by Youlong Xia, 17 June 2019
! !INTERFACE:
subroutine noah_main()
! !USES:
  use lisdrv_module, only : lis, grid
  use noah_varder      ! NOAH tile variables
  use tile_spmdMod
  
  use kwm_date_utilities
!EOP
  implicit none
  integer, parameter :: c1=0    !NO PRINT
!  integer, parameter :: c1=5600  ! PRINT
!  integer, parameter :: c1=1000000 ! PRINT    
! --------------------------------------------------------------------
!  INPUT VARIAVLES
! ----------basic integers for soil layer and time -------------------- 
  integer:: im        ! number of x direction grids
  integer:: km        ! numbers of soil layers (4)
  integer:: itime     ! timestep loop
  integer:: imon      ! ith month
  real:: djul         ! Julian day of the year
  integer:: yearlen   ! lengh of the year (365 for normal yr, 366 for leap yr)
! ----------- paramters for various model options ----------------------
  integer:: idveg     ! Dynamic vegeation(=2)
  integer:: iopt_crs  ! Ball-berry canopy stomatal resistence(=1)
  integer:: iopt_btr  ! Soil moisture factor for stomatal resistance(=1) 
  integer:: iopt_run  ! Topmodel with ground water(=1)
  integer:: iopt_sfc  ! M-O surace coefficient (=1)
  integer:: iopt_frz  ! No interation for supercooled liquid water(=1)
  integer:: iopt_inf  ! Linear soil permeability(=1)
  integer:: iopt_rad  ! Two-stream radiation transfer gap(=1)
  integer:: iopt_alb  ! CLASS for ground snow surface albedo(=2)
  integer:: iopt_snf  ! t1<tfrz precipitation partittion(=3)  
  integer:: iopt_tbot ! Noah lower bound cond. of soil T(=2)
  integer:: iopt_stc  ! Semi implicit scheme for Soil and snow T(=1)

! ------------ Meterological Forcing Data ------------------------------ 
  real:: tmp_ps           ! surface presure (pascals)
  real:: tmp_u1           ! x-direction 10m wind speed(m/s)
  real:: tmp_v1           ! Y-direction 10 m wind speed(m/s)
  real:: tmp_t1           ! 2m air temperature (K)
  real:: tmp_q1           ! 2m specific humidity(kg kg-1)  
  real:: tmp_dlwflx       ! downward longtwave radiation (w/m2)
  real:: tmp_dswsfc       ! downward shortwave radiation (w/m2)
  real:: tmp_snet         ! net sw radiation flux (dn-up) (w/m2)
  real:: tmp_prsl1        ! pressure at height zlvl above ground (pascals)
  real:: tmp_tprcp        ! total precipitation rate (mm)
  real:: tmp_prslki
! ------- noahmp various type precipitation ----------------------------
  real:: rainn_mp     ! non-convective precip forcing [mm]
  real:: rainc_mp     ! convective precip forcing [mm]
  real:: snow_mp      ! non-convective snowfall precip forcing [mm]
  real:: graupel_mp   ! non-convective graupel forcing [mm]
  real:: ice_mp       ! non-convective hail forcing [mm]

! soil and vegetation parameters 
  integer:: soiltyp      ! soil type
  integer:: vegtype      ! vegetation type
  integer:: slopetyp     ! slope type
  integer:: islimsk      ! land-water mask
  real:: sigmaf       ! greeness fraction
  real:: shdmax       ! maximum areal fractional coverage of green vegetation
  real:: shdmin       ! minimum areal fractional coverage of green vegetation
  real:: sfcemis      ! emissivity
  real:: tmp_tg3          ! Annually-fixed, soil-temp condition at ZBOT (K)
  real:: tmp_cm           ! Sfc. exchange coef. for heat and moisture
  real:: tmp_ch           ! Sfc. exchange coef. for momentum
!
  real:: xlatin       ! in radian
  real:: delt         ! time step length(seconds)
  real:: tmp_zf       ! forcing data height 
  real:: xcoszin      ! cosine zenith angle
  real:: snoalb       ! upper bound on maximum albedo over deep snow (fraction)
  real:: sfalb        ! backround snow-free surface albedo (fraction)
  
! -------------- flag options --------------------------------------
  logical:: flag_iter   ! initialization flag
  logical:: flag_guess  ! Restore land-related prognostic fields for guess run
 
! ----------------- noahmp outputted variables -----------------------
  real:: sncovr1      ! snow cover fraction [-]
  real:: qsurf        ! surface specific humidity [kg kg-1]
  real:: gflux        ! ground heat flux [w/m2]
  real:: drain        ! baseflow (saturation excess) [kg m-2 s-1]
  real:: evap1        ! total evapotranspiration [W m-2]
  real:: hflx         ! total sensible heat to atmosphere [W m-2]
  real:: ep           ! potential evapotranspiration [kg m-2 s-1]
  real:: runoff       ! surface runoff [kg m-2 s-1]
  real:: cmm          ! momentum drag coefficient [m s-1]
  real:: chh          ! sensible heat exchange coefficient [m s-1]
  real:: evbs         ! bare soil evaporation [W m-2]
  real:: evcw         ! vegeation transpiration [W m-2]
  real:: sbsno        ! snow sublimation [W m-2]
  real:: snowc        ! snow cover fraction [-]
  real:: stm          ! total column soil moisture  [-]
  real:: snohf        ! bottom snow melting flux [W m-2]
  real:: smcwlt2      ! soil moisture wilting point [-]
  real:: smcref2      ! soil moisture reference [-] 
  real:: wet1         ! top soil layer wetness smc/smcmax [-]
  real:: t2mmp        ! 2m air temperature [-]
  real:: q2mp         ! 2m specific humidity [kg kg-1]

! ---------------- time, lat, lon -------------------
  character(len=12)   :: nowdate 
  integer:: year    ! year of the current time step
  integer:: month   ! month of the current time step
  integer:: day     ! day of the current time step
  integer:: hour    ! hour of the current time step
  integer:: minute  ! minute of current time step
  real:: dt         ! time step in seconds
  real:: lat, lon   ! latitude and longitude

! local variable
  integer:: k
  integer:: i
  integer:: t
  integer:: IJ
  integer:: nroot  ! Number of root layers, dep. on veg. type
  real:: alb
  real:: cosz
  real:: T14
  real:: FUP
  real:: weva
  real:: SLDPTH(4)
  real:: soilrz
  real:: ddvel
  real:: con_hf
  
! Youlong Xia added
  real, allocatable:: zsnso(:)
  real, allocatable:: tsno(:)
  real, allocatable:: snice(:)
  real, allocatable:: snliq(:)
! end add
  
!BOC
 if(masterproc) then
 print*,"J---NOAH_MAIN (",iam,")"
 print*,"J---NOAH_MAIN di_array(iam) = ", di_array(iam)
 print*,"J---NOAH_MAIN lis%d%nch = ", lis%d%nch
 endif

    con_hf = 3.3358e+5
!=== Convert LDAS Timestep varname to noahmp timestep varname (delt) (sec)
   do t = 1, di_array(iam)
!    do t = c1, c1   

   lat = grid(t)%lat
   lon = grid(t)%lon
   year = lis%t%yr
   month = lis%t%mo
   day = lis%t%da
   hour = lis%t%hr
   minute = lis%t%mn
   delt = lis%t%ts
!  -------- model phyical parameterization schemes selcetd ------------
   idveg=1     
   iopt_crs=1
   iopt_btr=1 
   iopt_run=1
   iopt_sfc=1  
   iopt_frz=1  
   iopt_inf=1  
   iopt_rad=1 
   iopt_alb=2  
   iopt_snf=3 
   iopt_tbot=2 
   iopt_stc=1

   im=1
   km=4 

   flag_iter  = .true.
   flag_guess = .false.
! ------------- calculate cosz  ---------------------------------------   
  write(nowdate,'(I4.4,4I2.2)') year, month, day, hour, minute
  
  call calc_declin(nowdate(1:4)//"-"//nowdate(5:6)//"-"//nowdate(7:8)//"_" &
       //nowdate(9:10)//":"//nowdate(11:12)//":00", &
      lat, lon, cosz, yearlen, djul)
 
!=== Bottom Temperature Field
      tmp_tg3 = noah(t)%tempbot 
! ------------------------------------------------------------ 
      nroot = int(noah(t)%VEGP(1))
!J<<< jesse 20040507
      if ( t==c1 ) then
        WRITE(*,'(1X,A,A,I8,2(A,F8.3))') "J---NOAH_MAIN",&
             " GRID =",c1,&
             " LAT  =",grid(c1)%lat, " LON  =",grid(c1)%lon

          print*, "J---NOAH_MAIN VTYPE =", noah(t)%VEGT, &
                  "               SIBVEG =", noah(t)%SIBVEG
          write(*,'(A,7F10.2)') " J---NOAH_MAIN VEGP = ", &
                                (noah(t)%VEGP(i),i=1,7)
      endif
!J>>>
!=== MONTHLY VEGETATION PARAMETERS

! jesse - get gfrac from forcing sflux
!    Minimum greenness fraction
      shdmin=0.01
      SLDPTH(1) = 0.1         ! Soil layer thicknesses (m)
      SLDPTH(2) = 0.3
      SLDPTH(3) = 0.6
      SLDPTH(4) = 1.0

!=== STATIC SOIL PARAMETERS
      soiltyp = noah(t)%zobsoil(1)    ! STATISGO Soil Class Value    

      if(T.EQ.C1) then
          print*, "J---NOAH_MAIN STYPE =", noah(t)%ZOBSOIL
          write(*,'(A,5F10.6)') " J---NOAH_MAIN SOILP = ", &
                                (noah(t)%SOILP(i),i=1,5)
      endif

!JESSE 20130711 IGBP URBAN - vegetation type
      if(noah(t)%vegt == 13.)then
         sigmaf=0.05
      endif
      vegtype = int(noah(t)%vegt)
!      write(*,*) 'vegtyp =', noah(t)%vegt
!      write(*,*) 'soiltyp =', soiltyp 
!=== SLOPE TYPE
      slopetyp = 1

!=== MONTHLY (QUARTERLY, for now) ALBEDO (SNOW-FREE)

! jesse - get albedo from forcing sflux

!    Maximum Albedo over very Deep Snow

      snoalb = noah(t)%mxsnalb

!      write(*,*) 'tbot=', tmp_tg3      
!      write(*,*) 'vegtyp =', noah(t)%vegt
!      write(*,*) 'soiltyp =', soiltyp
!      write(*,*) 'SNOALB=', snoalb
!      stop
     
!=== THE FOLLOWING BREAKS DOWN THE FORCING VARIABLES
      if(T.EQ.C1) then
          write(*,*) 'noah(',c1,')%FORCING'
          write(*,'(16(1X,F12.4))') noah(t)%FORCING
      endif

      tmp_t1 = noah(t)%FORCING(1)
      tmp_q1 = noah(t)%FORCING(2)
      tmp_dswsfc  = noah(t)%FORCING(3)*0.97
      tmp_dlwflx   = noah(t)%FORCING(4)
      tmp_u1 = noah(t)%FORCING(5)
      tmp_v1 = noah(t)%FORCING(6)
      tmp_ps = noah(t)%FORCING(7)
      tmp_tprcp   = noah(t)%FORCING(8)
      sigmaf = noah(t)%FORCING(9)*0.01 
      sigmaf = MAX(sigmaf, 0.)
      sigmaf = MIN(sigmaf, 0.98)

!-- Height of observations (this needs to be modified)
!      Z = 6.0       ! Height of observations (m) UNCOUPLED
      tmp_zf   = noah(t)%FORCING(11)                ! COUPLED
      tmp_zf      = MAX(tmp_zf, 15.)

!-- Prevent Numerical Instability with HUMIDITY
      IF (tmp_q1 .LT. 0.1E-5)  tmp_q1 = 0.1E-5
!=== MAIN CALL TO LAND-SURFACE PHYSICS  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  tmp_ch =  noah(t)%FORCING(13)
  tmp_ch =  MAX(tmp_ch, 1.0E-4)
  tmp_cm =  noah(t)%FORCING(13)
  tmp_cm =  MAX(tmp_cm, 1.0E-4)
! ---------------------------------------------------------------------|
! NEW FOR NOAH 2.7.1
! ---------------------------------------------------------------------|
!--  input surface albedo
     alb = noah(t)%FORCING(10) * 0.01
     alb = MAX(alb, 0.05)
     alb = MIN(alb, 0.95)
     sfalb = alb
     tmp_snet= tmp_dswsfc*(1.0- alb)    
! ---------------------------------------------------------------------|
! QC FOR SNOW PROPERTIES. JESSE 20050106
! ---------------------------------------------------------------------|
      IF ( noah(t)%weasd .EQ. 0.0 ) THEN
           noah(t)%snwdph = 0.0
      ELSE
         IF ( noah(t)%snwdph .EQ. 0.0 ) THEN
             noah(t)%snwdph  = noah(t)%weasd * 10.
         ENDIF
      ENDIF 
! --------------------------------------------------------------------
! set variable value when they don't exist in uncoupled 
! --------------------------------------------------------------------
  shdmin   = 0.01
  shdmax    = 1.0
  itime    = 1
  sfcemis  = 1.0
  tmp_prsl1    = tmp_ps
  tmp_prslki   = tmp_ps
  ddvel   = 0.0

! vaious type precipiation
  rainn_mp   = 0.0
  rainc_mp   = 0.0
  snow_mp    = 0.0
  graupel_mp = 0.0
  ice_mp     = 0.0  
 
  if(tmp_t1 > 273.16) then           ! iopt_snf =3 - Noah rainfall-snowfall
  rainn_mp   = tmp_tprcp
  noah(t)%srflag = 0.0
  else
  snow_mp    = tmp_tprcp
  noah(t)%srflag = 1.0
  endif

! ---------------------------------------------------------------------|
! reset fluxes before noahmp driver
! ---------------------------------------------------------------------|
  evap1  = 0.0
  evbs   = 0.0
  evcw   = 0.0
  drain  = 0.0
  runoff = 0.0
  snohf  = 0.0
  gflux  = 0.0
  hflx  = 0.0
! ----------------allocate snow IC----------------|
  allocate(zsnso(-2:4))
  allocate(tsno(-2:0))
  allocate(snice(-2:0))
  allocate(snliq(-2:0))

  zsnso(-2:4) =  noah(t)%zsnsoxy(1:7)
  tsno(-2:0)  =  noah(t)%tsnoxy(1:3)
  snice(-2:0) =  noah(t)%snicexy(1:3)
  snliq(-2:0) = noah(t)%snliqxy(1:3)


  xlatin = lat
  xcoszin = cosz
  imon = lis%t%mo

  IF(T==C1) THEN
  write(*,*) '---------------- noahmp initials ---------'
      WRITE(*,*) 'stc',noah(t)%stc
      WRITE(*,*) 'smc',noah(t)%smc
      WRITE(*,*) 'slc',noah(t)%slc
  ENDIF
!*** call noahmp driver 
! ************* define land-water mask ------------------------------------
  IF (noah(t)%vegt.NE.15.0) THEN !IGBP SNOW AND ICE
     islimsk = 1     
   
!PRINT*,'J--BEFORE noahmap run--', 'T==', t, 'iam=', iam, 'veg=',  noah(t)%vegt
   call noahmpdrv                                             &
!...................................
!  ---  inputs:
          ( im, km,itime, tmp_ps, tmp_u1, tmp_v1, tmp_t1, tmp_q1, &
          soiltyp, vegtype, sigmaf, sfcemis, tmp_dlwflx,tmp_dswsfc, &
          tmp_snet, delt, tmp_tg3, tmp_cm, tmp_ch, tmp_prsl1, &
          tmp_prslki, tmp_zf, islimsk, ddvel, slopetyp, shdmin, &
          shdmax, snoalb, sfalb, flag_iter, flag_guess, idveg, &
          iopt_crs,  iopt_btr, iopt_run, iopt_sfc, iopt_frz, &
          iopt_inf,iopt_rad, iopt_alb, iopt_snf,iopt_tbot,iopt_stc, &
          xlatin,xcoszin, yearlen, djul,imon, &
          rainn_mp,rainc_mp,snow_mp,graupel_mp,ice_mp, &

!  ---  in/outs:
          noah(t)%weasd, noah(t)%snwdph, noah(t)%tskin, noah(t)%tprcp, &
          noah(t)%srflag, noah(t)%smc, noah(t)%stc, noah(t)%slc, &
          noah(t)%canopy, noah(t)%trans, noah(t)%tsurf, noah(t)%zorl, &

! --- Noah MP specified variable --------
          noah(t)%snowxy, noah(t)%tvxy, noah(t)%tgxy, noah(t)%canicexy, &
          noah(t)%canliqxy, noah(t)%eahxy,noah(t)%tahxy,noah(t)%cmxy, &
          noah(t)%chxy, noah(t)%fwetxy, noah(t)%sneqvoxy, noah(t)%alboldxy, &
          noah(t)%qsnowxy, noah(t)%wslakexy, noah(t)%zwtxy, noah(t)%waxy, &
          noah(t)%wtxy, tsno, zsnso, snice, snliq, noah(t)%lfmassxy, &
          noah(t)%rtmassxy, noah(t)%stmassxy,noah(t)%woodxy,noah(t)%stblcpxy, & 
          noah(t)%fastcpxy, noah(t)%xlaixy, noah(t)%xsaixy, noah(t)%taussxy, &
          noah(t)%smoiseq,noah(t)%smcwtdxy,noah(t)%deeprechxy,noah(t)%rechxy, &
!  ---  outputs:
          sncovr1,qsurf,gflux,drain,evap1,hflx, ep, runoff, cmm, chh, &
          evbs,evcw,sbsno,snowc,stm,snohf,smcwlt2,smcref2,wet1,t2mmp,q2mp)

!PRINT*,'J---DONE noahmap run-----', 'T==', t, 'iam=', iam, 'veg=', noah(t)%vegt    
 ELSE 
       noah(t)%smc  = 1.0
       noah(t)%slc = 1.0
       noah(t)%weasd = 0.1
       noah(t)%snwdph = 1.0
 ENDIF
! ------------- allocate snow variable back -------------------------
       noah(t)%zsnsoxy(1:7) = zsnso(-2:4)
       noah(t)%tsnoxy(1:3)  = tsno(-2:0)
       noah(t)%snicexy(1:3) = snice(-2:0)
       noah(t)%snliqxy(1:3) = snliq(-2:0)

 IF(T==C1) THEN
      WRITE(*,*) iam, 'J---NOAHMP_MAIN AFTER NOAHMP driver call ------'
      WRITE(*,*) iam, '  --------------------------------------'
      WRITE(*,*) iam, '  State Variables '
      WRITE(*,*) iam, '  --------------------------------------'
      WRITE(*,*) 'delt=', delt
      WRITE(*,*) 'TILE=', T, 'veg=', noah(t)%vegt
      WRITE(*,*) '========================================'
      WRITE(*,*) 'dlwflx,dswsfc,snet,ps,u1,v1,t1,q1'
WRITE(*,*) tmp_dlwflx,tmp_dswsfc,tmp_snet,tmp_ps,tmp_u1,tmp_v1,tmp_t1,tmp_q1
      WRITE(*,*) 'evap,eta,hflx,evbs,evcw,sbsno'
      WRITE(*,*) noah(t)%evap,hflx,evbs,evcw,sbsno
      WRITE(*,*)  'qle,qh,qg'
      WRITE(*,*)  evap1,hflx,gflux
      WRITE(*,*) 'prcp,qs,qsb'
      WRITE(*,*) tmp_tprcp,runoff,drain
      WRITE(*,*) 'tskin,canopy'
      WRITE(*,*) noah(t)%tskin, noah(t)%canopy
      WRITE(*,*) 'stc',noah(t)%stc
      WRITE(*,*) 'smc',noah(t)%smc
      WRITE(*,*) 'slc',noah(t)%slc
  ENDIF

  T14 = noah(t)%tsurf * noah(t)%tsurf * noah(t)%tsurf *noah(t)%tsurf
  FUP = 5.67E-8 * T14 * (0.95*snowc + 1.00*(1.0-snowc))
  
!******************************************************************
!   energy and water balance are checked in module_sf_noahmplsm.f90

  IF(T==C1) THEN
      WRITE(*,*) iam, 'J---NOAH_MAIN AFTER SFLX ---------------'
      WRITE(*,*) iam, '  --------------------------------------'
      WRITE(*,*) iam, '  State Variables '
      WRITE(*,*) iam, '  --------------------------------------'
  ENDIF

!******************************************************************
!=== Collect the output variables into noah(t)%RETURN
  !IF(T==C1) PRINT*,"energy"
      weva = evap1*2.45*1000000.0     ! convert mm/s into W/m2
      noah(t)%snet =  noah(t)%snet + tmp_snet            ! w/m2
      noah(t)%lwnet = noah(t)%lwnet + FUP - tmp_dlwflx   ! w/m2
      noah(t)%qle = noah(t)%qle + evap1               ! w/m2
      noah(t)%qh = noah(t)%qh + hflx                 ! w/m2
      noah(t)%qg = noah(t)%qg + gflux                ! w/m2 
      
  !IF(T==C1) PRINT*,"water"

         noah(t)%snowf = noah(t)%snowf+snow_mp
         noah(t)%rainf = noah(t)%rainf+rainn_mp

      weva = evap1*0.00072/1800.0    ! convert W/2 into mm/s
     
      noah(t)%evap = noah(t)%evap + evap1          ! mm/s 
      noah(t)%qs = noah(t)%qs + runoff            ! mm/s
      noah(t)%qsb = noah(t)%qsb + drain           ! mm/s
      noah(t)%qsm = noah(t)%qsm+snohf/con_hf   ! bottom snow layer snowmelt 
  !IF(T==C1) PRINT*,"surface"

      noah(t)%avgsurft=noah(t)%tsurf
      noah(t)%albedo=sfalb
      noah(t)%swe = noah(t)%weasd*1000.0       ! [unit: mm] 

  !IF(T==C1) PRINT*,"soil"

! soil moisture is instantaneous in [mm]
      noah(t)%soilmoist1 =noah(t)%smc(1)*1000.0*SLDPTH(1)
      noah(t)%soilmoist2 =noah(t)%smc(2)*1000.0*SLDPTH(2)
      noah(t)%soilmoist3 =noah(t)%smc(3)*1000.0*SLDPTH(3)
      noah(t)%soilmoist4 =noah(t)%smc(4)*1000.0*SLDPTH(4)
      noah(t)%soilwet = stm*2000.0            ! total column soil moisture
!  EC/ETT/EDIR in [W m-2]
      noah(t)%ecanop = noah(t)%ecanop + evcw
      noah(t)%tveg = noah(t)%tveg + noah(t)%trans
      noah(t)%esoil = noah(t)%esoil + evbs
      noah(T)%canopint = noah(t)%canopy         ! incepted water contant [mm]

! ROOT ZONE COLUMN SOIL MOISTURE IN METERS (SOILRZ)- here top 1m
      soilrz = 0.
      do k = 1,nroot
         soilrz = soilrz+(noah(t)%smc(k)*sldpth(k)*1000.0)
      end do
      noah(t)%rootmoist = soilrz

      if(lis%t%tscount == 0 .or. lis%t%tscount ==1 &
           .or.lis%f%rstflag.eq.1) then
   
        noah(t)%soilm_prev = noah(t)%soilmoist1 + noah(t)%soilmoist2 &
                           + noah(t)%soilmoist3 + noah(t)%soilmoist4
        noah(t)%swe_prev = noah(t)%swe
      endif
      
      noah(t)%count=noah(t)%count+1
      
      deallocate(zsnso)
      deallocate(tsno)
      deallocate(snice)
      deallocate(snliq)

      enddo 

  if(masterproc) PRINT*,"J---NOAH_MAIN(",iam,") END ---------------------------"
      return
!BOC
    end subroutine noah_main
  

  real function month_d(a12, nowdate) result (nowval)
  !
  ! Given a set of 12 values, taken to be valid on the fifteenth of each month (Jan through Dec)
  ! and a date in the form <YYYYMMDD[HHmmss]> ....
  !
  ! Return a value valid for the day given in <nowdate>, as an interpolation from the 12
  ! monthly values.
  !
  use kwm_date_utilities
  implicit none
  real, dimension(12), intent(in) :: a12 ! 12 monthly values, taken to be valid on the 15th of
  !                                      ! the month
  character(len=12), intent(in) :: nowdate ! Date, in the form <YYYYMMDD[HHmmss]>
  integer :: nowy, nowm, nowd
  integer :: prevm, postm
  real    :: factor
  integer, dimension(12) :: ndays = (/ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 /)

  !
  ! Handle leap year by setting the number of days in February for the year in question.
  !
  read(nowdate(1:8),'(I4,I2,I2)') nowy, nowm, nowd
  ndays(2) = nfeb(nowy)

  !
  ! Do interpolation between the fifteenth of two successive months.
  !
  if (nowd == 15) then
     nowval = a12(nowm)
     return
  else if (nowd < 15) then
     postm = nowm
     prevm = nowm - 1
     if (prevm == 0) prevm = 12
     factor = real(ndays(prevm)-15+nowd)/real(ndays(prevm))
  else if (nowd > 15) then
     prevm = nowm
     postm = nowm + 1
     if (postm == 13) postm = 1
     factor = real(nowd-15)/real(ndays(prevm))
  endif

  nowval = a12(prevm)*(1.0-factor) + a12(postm)*factor
  
  end function month_d

  SUBROUTINE calc_declin (nowdate, latitude, longitude, cosz, yearlen, julian)
  use kwm_date_utilities
!---------------------------------------------------------------------
  IMPLICIT NONE
!---------------------------------------------------------------------

  REAL, PARAMETER :: DEGRAD = 3.14159265/180.
  REAL, PARAMETER :: DPD    = 360./365.
! !ARGUMENTS:
  character(len=19), intent(in)  :: nowdate    ! YYYY-MM-DD_HH:mm:ss
  real,              intent(in)  :: latitude
  real,              intent(in)  :: longitude
  real,              intent(out) :: cosz
  integer,           intent(out) :: yearlen
  real,              intent(out) :: JULIAN

  REAL                           :: hrang
  real                           :: DECLIN
  real                           :: tloctim
  REAL                           :: OBECL
  REAL                           :: SINOB
  REAL                           :: SXLONG
  REAL                           :: ARG
  integer                        :: iyear
  integer                        :: iday
  integer                        :: ihour
  integer                        :: iminute
  integer                        :: isecond

  !
  ! Determine the number of days in the year
  !

  read(nowdate(1:4), '(I4)') iyear
  yearlen = 365
  if (mod(iyear,4) == 0) then
     yearlen = 366
     if (mod(iyear,100) == 0) then
        yearlen = 365
        if (mod(iyear,400) == 0) then
           yearlen = 366
           if (mod(iyear,3600) == 0) then
              yearlen = 365
           endif
        endif
     endif
  endif
 
  !
  ! Determine the Julian time (floating-point day of year).
  !

  call geth_idts(nowdate(1:10), nowdate(1:4)//"-01-01", iday)
  read(nowdate(12:13), *) ihour
  read(nowdate(15:16), *) iminute
  read(nowdate(18:19), *) isecond
  julian = real(iday) + real(ihour)/24.
  
!
! for short wave radiation

  DECLIN=0.

!-----OBECL : OBLIQUITY = 23.5 DEGREE.

  OBECL=23.5*DEGRAD
  SINOB=SIN(OBECL)

!-----CALCULATE LONGITUDE OF THE SUN FROM VERNAL EQUINOX:

  IF(JULIAN.GE.80.)SXLONG=DPD*(JULIAN-80.)*DEGRAD
  IF(JULIAN.LT.80.)SXLONG=DPD*(JULIAN+285.)*DEGRAD
  ARG=SINOB*SIN(SXLONG)
  DECLIN=ASIN(ARG)

  TLOCTIM = REAL(IHOUR) + REAL(IMINUTE)/60.0 + REAL(ISECOND)/3600.0 + LONGITUDE/15.0 ! Local time in hours
  tloctim = AMOD(tloctim+24.0, 24.0)
  HRANG=15.*(TLOCTIM-12.)*DEGRAD
  COSZ=SIN(LATITUDE*DEGRAD)*SIN(DECLIN)+COS(LATITUDE*DEGRAD)*COS(DECLIN)*COS(HRANG)
  COSZ=MIN(COSZ,1.0);   !Added by kwH 3/1/16 to address floating point roundoff errors
  COSZ=MAX(COSZ,-1.0);  !

!KWM   write(wrf_err_message,10)DECDEG/DEGRAD
!KWM10 FORMAT(1X,'*** SOLAR DECLINATION ANGLE = ',F6.2,' DEGREES.',' ***')
!KWM   CALL wrf_debug (50, wrf_err_message)

  END SUBROUTINE calc_declin

