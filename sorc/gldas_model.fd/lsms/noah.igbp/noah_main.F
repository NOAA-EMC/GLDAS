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
! !INTERFACE:
subroutine noah_main()
! !USES:
  use lisdrv_module, only : lis, grid
  use noah_varder      ! NOAH tile variables
  use tile_spmdMod
  use machine ,   only : kind_phys
!EOP
  implicit none
  integer, parameter :: c1=0    !NO PRINT
!  integer, parameter :: c1=1
!  integer, parameter :: c1=140213 !BON OF T382
!  integer, parameter :: c1=134768 !ARM OF T382
!  integer, parameter :: c1=180666
!  integer, parameter :: c1=1000000

  integer::kk
  INTEGER, PARAMETER:: NSOLD=4   ! Maximum number of soil layers
  INTEGER I,K         ! Loop integer
  
  INTEGER ICE         ! flag to invoke sea-ice physics (0=land)
  INTEGER NROOT       ! Number of root layers, dep. on veg. type 
  INTEGER NSOIL       ! Number of soil layers (used in noah_main.f)
  INTEGER NSLAY       ! Number of soil layers (from LDAS driver)     
  INTEGER SOILTYP     ! Soil type (integer index)
  INTEGER SIBVEG      ! SIB Vegetation class type (read into noah_main.f)
  INTEGER IJ          ! Elements of array by number of soil layers
  INTEGER T           ! Current tile NOAH model is called on, can be removed
  INTEGER SLOPETYP    ! Class of surface slope (integer index)
  REAL(KIND=KIND_PHYS):: SLOPE          ! Slope Estimate of linear reservoir coefficient  
  
  REAL(KIND=KIND_PHYS):: BETA           ! Ratio of actual/potential EVAP (dimensionless) 
  REAL(KIND=KIND_PHYS):: DRIP           ! Excess canopy moisture (m)
  REAL(KIND=KIND_PHYS):: EC             ! Canopy evaporation (m s-1)
  REAL(KIND=KIND_PHYS):: EDIR           ! Direct soil evaporation (m s-1)
  REAL(KIND=KIND_PHYS):: ET(NSOLD)      ! Plant transp. from each root/soil layer(m s-1)
  REAL(KIND=KIND_PHYS):: ETT            ! Accum plant transpiration (m s-1)
  REAL(KIND=KIND_PHYS):: ESNOW          ! Sublimation from snowpack (kg m-2 s-1) (or dep.)
  REAL(KIND=KIND_PHYS):: F              ! Net flux (TOT downward radiation)
  REAL(KIND=KIND_PHYS):: FXEXP          ! Bare soil evaporation exponent used in DEVAP
  REAL(KIND=KIND_PHYS):: FLX1           ! Precip-snow Surface  (W M-2)
  REAL(KIND=KIND_PHYS):: FLX2           ! Freezing rain latent heat flux (W M-2)
  REAL(KIND=KIND_PHYS):: FLX3           ! Phase-change heat flux from snowmelt (W M-2)
  REAL(KIND=KIND_PHYS):: DEW            ! Dewfall amount  (m s-1)
  REAL(KIND=KIND_PHYS):: RIB            ! Bulk Richardson Number
  REAL(KIND=KIND_PHYS):: RUNOFF1        ! Ground surface runoff (m/s)
  REAL(KIND=KIND_PHYS):: RUNOFF2        ! Underground runoff (m/s)
  REAL(KIND=KIND_PHYS):: RUNOFF3        ! Runoff within soil layers (m/s)
  REAL(KIND=KIND_PHYS):: SIGMA          ! Stefan-Boltzmann constant (5.672E-8 W m-2 T-4)
  REAL(KIND=KIND_PHYS):: Q1             ! Effective mixing ratio at grnd sfc (kg kg-1)
  REAL(KIND=KIND_PHYS):: AET            ! Actual evapotranspirative energy (J m-2 s-1)
  REAL(KIND=KIND_PHYS):: ALB            ! Quarterly Snow-free albedo (fraction)
  REAL(KIND=KIND_PHYS):: ALBEDO         ! Total Sfc. albedo fraction (incl. snow-max alb)
  REAL(KIND=KIND_PHYS):: CH             ! Sfc. exchange coef. for heat and moisture
  REAL(KIND=KIND_PHYS):: CM             ! Sfc. exhcange coef. for momentum
  REAL(KIND=KIND_PHYS):: CMC            ! initial canopy water content (m)
  REAL(KIND=KIND_PHYS):: CCOND          ! Canopy Conductance (m s-1) 
  REAL(KIND=KIND_PHYS):: DQSDT          ! Slope of sat. specific hum. curve for Penman
  REAL(KIND=KIND_PHYS):: CZIL           ! (Zilintinkevich coef)
  REAL(KIND=KIND_PHYS):: REFKDT         ! Scalar surface runoff parameter 
  REAL(KIND=KIND_PHYS):: REFDK          ! A reference value for KDT
  REAL(KIND=KIND_PHYS):: KDT            ! Based on REFKDT, DKSAT, and REFDK 
  REAL(KIND=KIND_PHYS):: FRZK           ! Ice content threshold in soil 
  REAL(KIND=KIND_PHYS):: FRZX           ! Adjust FRZK Parameter to actual soil type 
  REAL(KIND=KIND_PHYS):: FRZFACT        ! Used in ice content in soil 
  REAL(KIND=KIND_PHYS):: FFROZP         ! Flag used for precipitation type  (NEW)
  REAL(KIND=KIND_PHYS):: DQSDT2         ! Slope of sat. specific hum. curve for Penman
  REAL(KIND=KIND_PHYS):: DT             ! time step length (sec) of physical integration
  REAL(KIND=KIND_PHYS):: EMISS          ! Longwave "emission" = epsilon
  REAL(KIND=KIND_PHYS):: ESAT           ! Saturation vapor pressure for water (Pa)
  REAL(KIND=KIND_PHYS):: QSAT           ! Saturation Specific humidity (Kg/Kg)
  REAL(KIND=KIND_PHYS):: E              ! Saturation vapor pressure
  
  REAL(KIND=KIND_PHYS):: ETA            ! Actual latent heat flux (W m-2) (NEG: up from sfc)
  REAL(KIND=KIND_PHYS):: EVP            ! Total Evaporation (kg/m2s) (=EC+ETT+EDIR)
  REAL(KIND=KIND_PHYS):: ETP            ! Final Potential Evapotransp. (W m-2)
  REAL(KIND=KIND_PHYS):: FUP            ! Upward ground LW radiation (W m-2)
  REAL(KIND=KIND_PHYS):: SHTFLX         ! Sensible heat flux (W m-2)
  REAL(KIND=KIND_PHYS):: SOLDN          ! Solar downward radiation (W m-2; positive,
                      !   not net shortwave)
  REAL(KIND=KIND_PHYS):: SOLUP          !  (NEW) SOLDN*ALBEDO - OUTPUT to SFLX
  REAL(KIND=KIND_PHYS):: SOLNET         !  (NEW) SOLDN*(1.0-ALBEDO) - INPUT to SFLX
  REAL(KIND=KIND_PHYS):: LWDN           ! Downward Longwave radiation (W/m2)
  REAL(KIND=KIND_PHYS):: PRCP           ! Precipitation rate conversion (kg m-2 s-1)
  REAL(KIND=KIND_PHYS):: CPCP           ! Convective Precipitation (kg m-2 s-1)
  REAL(KIND=KIND_PHYS):: ASNOW          ! The snowfall rate (kg m-2 s-1)
  REAL(KIND=KIND_PHYS):: PTU            ! Phota Thermal Unit (dep. on air temp and rad)
  
  REAL(KIND=KIND_PHYS):: Q2             ! Mixing ratio at 1st middle level above skin
  REAL(KIND=KIND_PHYS):: Q2SAT          ! Sat. Mix. ratio at 1st middle level above skin
  REAL(KIND=KIND_PHYS):: RES            ! Energy Balance equation residual (W m-2)
  REAL(KIND=KIND_PHYS):: RNET           ! net radiation (W/m2)
  REAL(KIND=KIND_PHYS):: SFCSPD         ! Wind speed, sqrt(u*u+v*v)
  REAL(KIND=KIND_PHYS):: UWIND          ! U-Wind component (m s-1)
  REAL(KIND=KIND_PHYS):: VWIND          ! V-Wind component (m s-1)
  REAL(KIND=KIND_PHYS):: SFCPRS         ! Surface pressure (Pascals)
  REAL(KIND=KIND_PHYS):: SFCTMP         ! Surface temperature (K)
  REAL(KIND=KIND_PHYS):: SHDFAC         ! 12-month green vegetation fraction
  REAL(KIND=KIND_PHYS):: SHDMIN         ! Fixed minimum green veg fraction
  REAL(KIND=KIND_PHYS):: SHDMAX         ! Fixed maximum green veg fraction

!      REAL(KIND=KIND_PHYS):: MLAI(13)       ! Monthly leaf area index values

  REAL(KIND=KIND_PHYS):: SMC(NSOLD)     ! Initial vol. soil moisture of each layer
  REAL(KIND=KIND_PHYS):: SNOMLT         ! Snow melt (m) (water equivalent)
  REAL(KIND=KIND_PHYS):: SNOALB         ! Maximum albedo expected over deep snow
  REAL(KIND=KIND_PHYS):: MSTAVRZ        ! Avail root zone soil moisture (unitless fraction)
  REAL(KIND=KIND_PHYS):: MSTAVTOT       ! Total Column Soil Moisture Availability (%)
  REAL(KIND=KIND_PHYS):: SOILM          ! Total soil column water content (m->kg/m2)
  REAL(KIND=KIND_PHYS):: SOILRZ         ! Root zone soil column water content (kg/m2)
  REAL(KIND=KIND_PHYS):: SOIL1M         ! Top 1-m soil column water content (kg/m2)
  REAL(KIND=KIND_PHYS):: STC(NSOLD)     ! Initial soil temperature (K) of each soil layer
  REAL(KIND=KIND_PHYS):: GFLX           ! Soil heat flux (W m-2)
!      REAL(KIND=KIND_PHYS):: T1             ! Initial skin temperature (K) 
  REAL(KIND=KIND_PHYS):: T14            ! Ground sfc. temp. to the 4th power (K^+4)
  REAL(KIND=KIND_PHYS):: T1V            ! Virtual temperature at ground (sub 1)
  REAL(KIND=KIND_PHYS):: T2V            ! Virtual temp. at 1st mid. lev. above grnd (2)
! LW    REAL(KIND=KIND_PHYS):: TAK            ! Air temperature in K
  REAL(KIND=KIND_PHYS):: TBOT           ! Annually-fixed, soil-temp condition at ZBOT
  REAL(KIND=KIND_PHYS):: TH2            ! Potential temperature (K) at hgt z above grnd
  REAL(KIND=KIND_PHYS):: TH2V           ! Virtual potential temperature (K) at z
  REAL(KIND=KIND_PHYS):: Z              ! Height (meters) above ground in atmos. forcing
  REAL(KIND=KIND_PHYS):: Z0             ! Roughness length parameter
  
  REAL(KIND=KIND_PHYS):: PCPDAY         ! Daily accumulation of precipitation (mm)
  REAL(KIND=KIND_PHYS):: PCPSUM         ! Daily accumulation of precipitation (mm)
  REAL(KIND=KIND_PHYS):: ETADAY         ! Daily accumulation of actual evapotranp. (mm)
  REAL(KIND=KIND_PHYS):: ETSUM          ! Daily accumulation of actual evapotranp. (mm)
  REAL(KIND=KIND_PHYS):: RUNOFFSUM      ! Accum. daily values in mm for runoff (mm)
  REAL(KIND=KIND_PHYS):: RUNOFFDAY      ! Accum. daily values in mm for runoff
  REAL(KIND=KIND_PHYS):: SMCNW          ! SLDPTH(ij)*1000.*SMC(ij) + SMCNW
  
  REAL(KIND=KIND_PHYS):: SH2O(NSOLD)    ! Initial vol. liq. soil moisture of each layer
  REAL(KIND=KIND_PHYS):: SLDPTH(4)      ! Thickness values for NSOIL layers (meters)
  REAL(KIND=KIND_PHYS):: SNOWH          ! Snow depth (meters)
  REAL(KIND=KIND_PHYS):: SNEQV          ! Snow water-equivalent (m) above snowdepth
  REAL(KIND=KIND_PHYS):: SNCOVR         ! FRACTIONAL SNOW COVER (UNITLESS FRACTION, 0-1)
  REAL(KIND=KIND_PHYS):: SNDENS         ! Snow Density  (NEW)
 
  REAL(KIND=KIND_PHYS):: RSMIN          ! MINIMUM CANOPY RESISTANCE (S M-1)
  REAL(KIND=KIND_PHYS):: RGL            ! FROM SOLAR RAD TERM OF CANOPY RESISTANCE FUNCTION
  REAL(KIND=KIND_PHYS):: HS             ! USED IN VAPOR PRESS. DEF. TERM OF CAN. RES. FUNCTION
  REAL(KIND=KIND_PHYS):: SNUP           ! THRESHOLD SNOW DEPTH (IN WATER EQUIVALENT M) THAT
  !  IMPLIES 100% SNOW COVER
  REAL(KIND=KIND_PHYS):: XLAI           ! LEAF AREA INDEX (DIMENSIONLESS)
  REAL(KIND=KIND_PHYS):: RC             ! CANOPY RESISTANCE (S M-1)
  REAL(KIND=KIND_PHYS):: PC             ! PLANT COEFFICIENT (UNITLESS FRACTION, 0-1) WHERE
  !   PC*ETP = ACTUAL TRANSP
  REAL(KIND=KIND_PHYS):: RCS            ! INCOMING SOLAR RC FACTOR (DIMENSIONLESS)
  REAL(KIND=KIND_PHYS):: RCT            ! AIR TEMPERATURE RC FACTOR (DIMENSIONLESS)
  REAL(KIND=KIND_PHYS):: RCQ            ! ATMOS VAPOR PRESSURE DEFICIT RC FACTOR (DIMENSIONLESS)
  REAL(KIND=KIND_PHYS):: RCSOIL         ! SOIL MOISTURE RC FACTOR (DIMENSIONLESS)
  
  REAL(KIND=KIND_PHYS):: SMCMAX         ! MAX SOIL MOISTURE CONTENT (POROSITY)
  REAL(KIND=KIND_PHYS):: SMCREF         ! REFERENCE SOIL MOISTURE (ONSET OF SOIL MOISTURE
  !  STRESS IN TRANSPIRATION) - Volumetric
  REAL(KIND=KIND_PHYS):: SMCREF1
  REAL(KIND=KIND_PHYS):: SMCWLT         ! WILTING Point (VOLUMETRIC)
  REAL(KIND=KIND_PHYS):: SMCWLT1
  REAL(KIND=KIND_PHYS):: SMCDRY         ! DRY SOIL MOIST THRESHOLD - DIRECT EVAP 
  !  FRM TOP LAYER ENDS (VOLUMETRIC)
  REAL(KIND=KIND_PHYS):: PSISAT         ! SATURATED SOIL POTENTIAL
  REAL(KIND=KIND_PHYS):: DKSAT          ! SATURATED SOIL HYDRAULIC CONDUCTIVITY
  REAL(KIND=KIND_PHYS):: BEXP           ! THE 'B' PARAMETER
  REAL(KIND=KIND_PHYS):: DWSAT          ! SATURATED SOIL DIFFUSIVITY
  REAL(KIND=KIND_PHYS):: F1             ! USED TO COMPUTE SOIL DIFFUSIVITY/CONDUCTIVITY
  REAL(KIND=KIND_PHYS):: QUARTZ         ! SOIL QUARTZ CONTENT
  REAL(KIND=KIND_PHYS):: SMLOW          ! Soil moisture wilt and reference parameter
  REAL(KIND=KIND_PHYS):: SMHIGH         ! Soil moisture wilt and reference parameter
  REAL(KIND=KIND_PHYS), PARAMETER:: R = 287.04
  REAL(KIND=KIND_PHYS), PARAMETER:: CP = 1004.5
  
  REAL(KIND=KIND_PHYS), PARAMETER:: T0 = 273.15       ! Freezing point in Kelvin (273.15 K)
  REAL(KIND=KIND_PHYS), PARAMETER:: LVH2O = 2.501000E+6 ! Latent heat for evapo for water  
  
  REAL(KIND=KIND_PHYS), PARAMETER:: EPS = 0.622 ! Water/(dry air) molec mass ratio (epsilon)
  integer :: II
  real(kind=kind_phys) :: soilmtc

! added for v2.7gfs
      integer couple
      real(kind=kind_phys):: sfcems
      integer ivegsrc
      real(kind=kind_phys):: bexpp
      real(kind=kind_phys):: soilw
      real(kind=kind_phys):: xlaip
      logical lheatstrg
!BOC
 if(masterproc) then
 print*,"J---NOAH_MAIN (",iam,")"
 print*,"J---NOAH_MAIN di_array(iam) = ", di_array(iam)
 print*,"J---NOAH_MAIN lis%d%nch = ", lis%d%nch
 endif

!=== Convert LDAS Timestep varname to NOAH timestep varname (DT) (sec)
  do t = 1, di_array(iam)
!  do t = c1, c1
!  if(t.EQ.di_array(iam)) then
!    PRINT*,"TILE(",T,")"
!  endif
      soilmtc = 0.0
      dt = lis%t%ts
!=== Bottom Temperature Field
      tbot = noah(t)%tempbot
!=== VEGETATION CLASS

!=== STATIC VEGETATION PARAMETERS
! ----------------------------------------------------------------------
! VEGETATION PARAMETERS ARE DEPENDENT ON VEGETATION TYPE (INDEX)
!   SHDFAC: VEGETATION GREENNESS FRACTION
!   NROOT:  NUMBER OF ROOT LAYERS
!   RSMIN:  MIMIMUM STOMATAL RESISTANCE
!   RGL:    PARAMETER USED IN SOLAR RAD TERM OF
!           CANOPY RESISTANCE FUNCTION
!   HS:     PARAMETER USED IN VAPOR PRESSURE DEFICIT TERM OF
!           CANOPY RESISTANCE FUNCTION
!   SNUP:   THRESHOLD SNOW DEPTH (IN WATER EQUIVALENT M) THAT
!           IMPLIES 100% SNOW COVER
!   Z0:     Roughness Length
!   XLAI:   Leaf Area Index
! ----------------------------------------------------------------------
! SSIB VEGETATION TYPES (DORMAN AND SELLERS, 1989; JAM)
!  1:  BROADLEAF-EVERGREEN TREES  (TROPICAL FOREST)
!  2:  BROADLEAF-DECIDUOUS TREES
!  3:  BROADLEAF AND NEEDLELEAF TREES (MIXED FOREST)
!  4:  NEEDLELEAF-EVERGREEN TREES
!  5:  NEEDLELEAF-DECIDUOUS TREES (LARCH)
!  6:  BROADLEAF TREES WITH GROUNDCOVER (SAVANNA)
!  7:  GROUNDCOVER ONLY (PERENNIAL)
!  8:  BROADLEAF SHRUBS WITH PERENNIAL GROUNDCOVER
!  9:  BROADLEAF SHRUBS WITH BARE SOIL
! 10:  DWARF TREES AND SHRUBS WITH GROUNDCOVER (TUNDRA)
! 11:  BARE SOIL
! 12:  CULTIVATIONS (THE SAME PARAMETERS AS FOR TYPE 7)
! 13:  GLACIAL (THE SAME PARAMETERS AS FOR TYPE 11)
! ----------------------------------------------------------------------

      NROOT = NOAH(T)%VEGP(1)
      RSMIN = NOAH(T)%VEGP(2)
      RGL   = NOAH(T)%VEGP(3)
      HS    = NOAH(T)%VEGP(4)
      SNUP  = NOAH(T)%VEGP(5)
      Z0    = NOAH(T)%VEGP(6)
      XLAI  = NOAH(T)%VEGP(7)

!J<<< jesse 20040507
      if ( t==c1 ) then
        WRITE(*,'(1X,A,A,I8,2(A,F8.3))') "J---NOAH_MAIN",&
             " GRID =",c1,&
             " LAT  =",grid(c1)%lat, " LON  =",grid(c1)%lon

          print*, "J---NOAH_MAIN VTYPE =", NOAH(T)%VEGT, &
                  "               SIBVEG =", NOAH(T)%SIBVEG
          write(*,'(A,7F10.2)') " J---NOAH_MAIN VEGP = ", &
                                (NOAH(T)%VEGP(i),i=1,7)
      endif
!J>>>
!=== MONTHLY VEGETATION PARAMETERS

! jesse - get gfrac from forcing sflux

!      SHDFAC = NOAH(T)%VEGIP

!    Minimum and Maximum greenness fraction
!      SHDMIN=0.0
      shdmin=noah(t)%vegmp1
      shdmax=noah(t)%vegmp2

!    If ground surface is bare:
!      IF (noah(t)%VEGT .EQ. 11) SHDFAC = 0.0

!=== STATIC SOIL PARAMETERS
! ----------------------------------------------------------------------
!  SOIL PARAMETERS ARE DEPENDENT ON SOIL TYPE (INDEX)
!    SMCMAX: MAX SOIL MOISTURE CONTENT (POROSITY)
!    SMCREF: REFERENCE SOIL MOISTURE (ONSET OF SOIL MOISTURE
!             STRESS IN TRANSPIRATION)
!    SMCWLT: WILTING PT SOIL MOISTURE CONTENT
!    SMCDRY: AIR DRY SOIL MOIST CONTENT LIMITS
!    PSISAT: SATURATED SOIL POTENTIAL
!    DKSAT:  SATURATED SOIL HYDRAULIC CONDUCTIVITY
!    BEXP:   THE 'B' PARAMETER
!    DWSAT:  SATURATED SOIL DIFFUSIVITY
!    F1:     USED TO COMPUTE SOIL DIFFUSIVITY/CONDUCTIVITY
!    QUARTZ: SOIL QUARTZ CONTENT
! ----------------------------------------------------------------------
! SOIL TYPES   ZOBLER (1986)      COSBY ET AL (1984) (quartz cont.(1))
!  1        COARSE            LOAMY SAND         (0.82)
!  2        MEDIUM            SILTY CLAY LOAM    (0.10)
!  3        FINE              LIGHT CLAY         (0.25)
!  4        COARSE-MEDIUM     SANDY LOAM         (0.60)
!  5        COARSE-FINE       SANDY CLAY         (0.52)
!  6        MEDIUM-FINE       CLAY LOAM          (0.35)
!  7        COARSE-MED-FINE   SANDY CLAY LOAM    (0.60)
!  8        ORGANIC           LOAM               (0.40)
!  9        GLACIAL LAND ICE  LOAMY SAND         (NA using 0.82)
! ----------------------------------------------------------------------
       
      NSOIL  =  4             ! 4 soil layers in NOAH 

      SLDPTH(1) = 0.1         ! Soil layer thicknesses (m)
      SLDPTH(2) = 0.3
      SLDPTH(3) = 0.6
      SLDPTH(4) = 1.0
      
      SOILTYP = NOAH(T)%ZOBSOIL(1)    ! Zobler Soil Class Value
      
      SMCMAX =  NOAH(T)%SOILP(1)
      PSISAT =  NOAH(T)%SOILP(2)
      DKSAT  =  NOAH(T)%SOILP(3)
      BEXP   =  NOAH(T)%SOILP(4)
      QUARTZ =  NOAH(T)%SOILP(5)
 
      if(T.EQ.C1) then
          print*, "J---NOAH_MAIN STYPE =", NOAH(T)%ZOBSOIL
          write(*,'(A,5F10.6)') " J---NOAH_MAIN SOILP = ", &
                                (NOAH(T)%SOILP(i),i=1,5)
      endif

!   The following 5 parameters are just given here for reference
!    and to force static storage allocation.

!       SMCREF =  NOAH%SOILP(6)
!       SMCWLT =  NOAH%SOILP(7)
!       SMCDRY =  NOAH%SOILP(8)
!       DWSAT  =  NOAH%SOILP(9)
!       F1     =  NOAH%SOILP(10)

!-- Here is where the above five parameters are actually derived.
!    SET TWO SOIL MOISTURE WILT, SOIL MOISTURE REFERENCE PARAMETERS
      SMLOW = 0.5
!     Changed in 2.6 from 3 to 6 on June 2nd 2003
!       SMHIGH = 3.0
      SMHIGH = 6.0

      DWSAT  = BEXP * DKSAT * (PSISAT/SMCMAX)
      F1     = LOG10(PSISAT) + BEXP*LOG10(SMCMAX) + 2.0
      SMCREF1 = SMCMAX*(5.79E-9/DKSAT)**(1.0/(2.0*BEXP+3.0))
      SMCREF = SMCREF1 + (SMCMAX-SMCREF1) / SMHIGH
      SMCWLT1 = SMCMAX * (200.0/PSISAT)**(-1.0/BEXP)
      SMCWLT = SMCWLT1 - SMLOW * SMCWLT1
!    Current version SMCDRY values equate to SMCWLT
      SMCDRY = SMCWLT

!JESSE 20130711 IGBP URBAN
      if(noah(t)%vegt == 13.)then
         shdfac=0.05
         rsmin=400.0
         smcmax = 0.45
         smcref = 0.42
         smcwlt = 0.40
         smcdry = 0.40
      endif

!
      if(T.EQ.C1) then
          write(*,'(23X,5F10.6)') SMCREF, SMCWLT, SMCWLT, DWSAT, F1
      endif

! ----------------------------------------------------------------------
! KDT IS DEFINED BY REFERENCE REFKDT AND DKSAT; REFDK=2.E-6 IS THE SAT.
! DK. VALUE FOR THE SOIL TYPE 2
! ----------------------------------------------------------------------
      REFDK=2.0E-6
      REFKDT=3.0
      KDT = REFKDT * DKSAT/REFDK

! ----------------------------------------------------------------------
! FROZEN GROUND PARAMETER, FRZK, DEFINITION: ICE CONTENT THRESHOLD ABOVE
! WHICH FROZEN SOIL IS IMPERMEABLE REFERENCE VALUE OF THIS PARAMETER FOR
! THE LIGHT CLAY SOIL (TYPE=3) FRZK = 0.15 M.
! ----------------------------------------------------------------------
      FRZK=0.15
! ----------------------------------------------------------------------
! TO ADJUST FRZK PARAMETER TO ACTUAL SOIL TYPE: FRZK * FRZFACT
! ----------------------------------------------------------------------
      FRZFACT = (SMCMAX / SMCREF) * (0.412 / 0.468)
      FRZX = FRZK * FRZFACT

!=== SLOPE TYPE
! ----------------------------------------------------------------------
! CLASS PARAMETER 'SLOPETYP' WAS INCLUDED TO ESTIMATE LINEAR RESERVOIR
! COEFFICIENT 'SLOPE' TO THE BASEFLOW RUNOFF OUT OF THE BOTTOM LAYER.
! LOWEST CLASS (SLOPETYP=0) MEANS HIGHEST SLOPE PARAMETER = 1.
! DEFINITION OF SLOPETYP FROM 'ZOBLER' SLOPE TYPE:
! SLOPE CLASS  PERCENT SLOPE
! 1            0-8
! 2            8-30
! 3            > 30
! 4            0-30
! 5            0-8 & > 30
! 6            8-30 & > 30
! 7            0-8, 8-30, > 30
! 8            GLACIAL ICE
! 9            OCEAN/SEA
! ----------------------------------------------------------------------

!--  SLOPETYP = 3
      SLOPE = 1.0

!=== MONTHLY (QUARTERLY, for now) ALBEDO (SNOW-FREE)

! jesse - get albedo from forcing sflux

!      ALB =  NOAH(T)%ALBSF

!    Maximum Albedo over very Deep Snow

      SNOALB = NOAH(T)%MXSNALB

!=== THE FOLLOWING BREAKS DOWN THE FORCING VARIABLES
      if(T.EQ.C1) then
          write(*,*) 'noah(',c1,')%FORCING'
          write(*,'(16(1X,F10.4))') noah(t)%FORCING
      endif

      SFCTMP = noah(t)%FORCING(1)
      Q2     = noah(t)%FORCING(2)
      SOLDN  = noah(t)%FORCING(3)
      LWDN   = noah(t)%FORCING(4)
      UWIND  = (noah(t)%FORCING(5))*(noah(t)%FORCING(5))
      VWIND  = (noah(t)%FORCING(6))*(noah(t)%FORCING(6))
      SFCSPD = SQRT( UWIND + VWIND )
      SFCPRS = noah(t)%FORCING(7)
      PRCP   = noah(t)%FORCING(8)
      SHDFAC = noah(t)%FORCING(9)*0.01 
      SHDFAC = MAX(SHDFAC, 0.)
      SHDFAC = MIN(SHDFAC, 1.)

!-- Height of observations (this needs to be modified)
!      Z = 6.0       ! Height of observations (m) UNCOUPLED
      Z      = noah(t)%FORCING(11)                ! COUPLED
      Z      = MAX(Z, 15.)
!      Z0     = noah(t)%FORCING(12)
!      IF (Z0 .LT. 0.01) Z0 = NOAH(T)%VEGP(6)
      Z0 = NOAH(T)%VEGP(6)

!-- Prevent Numerical Instability for Wind Speed
      IF (SFCSPD .LT. 0.01) SFCSPD=0.01

!-- Prevent Numerical Instability with HUMIDITY

      IF (Q2 .LT. 0.1E-5)  Q2 = 0.1E-5

! Calculate Saturation Specific Humidity (Kg/Kg) and
!    Saturation vapor pressure for water (Pa) based on Specific
!    Humidity(Kg/Kg), Temperature(K), and Pressure (Pa)
!
!      FORMULAS AND CONSTANTS FROM ROGERS AND YAU, 1989: 'A
!      SHORT COURSE IN CLOUD PHYSICS', PERGAMON PRESS, 3rd ED.
!        Pablo J. Grunmann, 3/6/98.
!
!      QSAT  = Saturation Specific humidity (Kg/Kg)
!      ESAT  = Saturation vapor pressure for water (Pa)
!      EPS   = Water/(dry air) molecular mass ratio (epsilon)
!      E     = Saturation vapor pressure
!
!-- Function E(SFCTMP) = Sat. vapor pressure (in Pascal) at
!                   temperature T (uses Clausius-Clapeyron).

      ESAT = E(SFCTMP)

!-- CALCULATE SATURATION MIXING RATIO (PABLO GRUNMANN, 05/28/98)

      Q2SAT = 0.622 * ESAT /(SFCPRS - (1.-0.622)*ESAT)
      IF (Q2 .GE.  Q2SAT)  Q2 = Q2SAT*0.99
       
!-- CALCULATE SLOPE OF SAT. SPECIFIC HUMIDITY CURVE FOR PENMAN: DQSDT2

      DQSDT2 = DQSDT (SFCTMP, SFCPRS)

!-- CALC VIRTUAL TEMPS AND POTENTIAL TEMPS AT GRND (SUB 1) AND AT
!    THE 1ST MDL LVL ABV THE GRND (SUB 2). EXPON IS CP DIVD BY R.

!      noah(t)%T1 = noah(t)%FORCING(14)

      TH2 = SFCTMP + ( 0.0098 * Z )
      T2V = SFCTMP * (1.0 + 0.61 * Q2 )
      
      T1V  =  noah(t)%T1 * (1.0 + 0.61 * Q2 )
      TH2V = TH2 * (1.0 + 0.61 * Q2 )

!==  OPTIONAL SUBROUTINE:  Calculate LW Radiation (Down)  =================
!      CALL OBTLWDN(SFCTMP,LWDN)

!--  Phota Thermal Unit (PTU)

      PTU    = 0.10

!--  Initialize SOILM for 1st timestep water balance
!       SOILM = 0.0
!--  Initialize ROOT ZONE COLUMN SOIL MOISTURE IN METERS (SOILRZ)
      SOILRZ = 0.0
!--  Initialize TOP 1-METER COLUMN SOIL MOISTURE IN METERS (SOIL1M)
      SOIL1M = 0.0

!==  CALCULATE CH (EXCHANGE COEFFICIENT)  =================================
!
!   CH IS THE SFC EXCHANGE COEFFICIENT FOR HEAT/MOISTURE
!   CM IS THE SFC EXCHANGE COEFFICIENT FOR MOMENTUM
!
! IMPORTANT NOTE: TO CALCULATE THE SFC EXCHANGE COEF (CH) FOR HEAT AND
!                 MOISTURE, SUBROUTINE SFCDIF BELOW CAN:
!
!    A)  BE CALLED HERE FROM THE DRIVER, THUS CH IS INPUT TO SFLX
!           (AS IS TYPICAL IN A COUPLED ATMOSPHERE/LAND MODEL), OR
!  * B)  BE CALLED INTERNALLY IN ROUTINE SFLX (THUS CH IS OUTPUT FROM SFLX),
!          BEFORE THE CALL TO ROUTINE "PENMAN"
!
!   OPTION B IS THE DEFAULT HERE.  THAT IS, IN THE UNCOUPLED, OFF-LINE LSM
!   REPRESENTED HEREIN BY THIS DRIVER, WE CALL SFCDIF LATER IN ROUTINE SFLX.
!
!   THE ROUTINE SFCDIF REPRESENTS THE SO-CALLED "SURFACE LAYER" OR THE
!   "CONSTANT FLUX LAYER" (THE LOWEST 20-100 M OF THE ATMOSPHERE).
!   HENCE ROUTINE SFCDIF EMBODIES THE "ATMOSPHERIC AERODYNAMIC RESISTANCE".
!
!   TO ENABLE THE FLEXIBILITY OF EITHER OPTION A OR B, WE PASS
!   THE ARGUMENTS "CH", "CM", AND "SFCSPD" (WIND SPEED:JUST CALCULATED ABOVE)
!   TO ROUTINE SFLX TO SUPPORT OPTION B -- THAT IS, FOR INPUT TO THE CALL TO
!   ROUTINE SFCDIF THEREIN.  IN OPTION A, THE ARGUMENTS "SFCSPD" AND "CM"
!   ARE NEITHER NEEDED IN ROUTINE SFLX, NOR ALTERED BY ROUTINE SFLX.
!
!     IF ONE CHOOSES OPTION A, THEN ONE MUST
!      1 - ACTIVATE (UNCOMMENT) THE CALL TO SFCDIF BELOW,
!      2 - ACTIVATE (UNCOMMENT) THE ASSIGNMENT OF "Z0" AND "CZIL" NEXT BELOW
!      3 - DE-ACTIVATE (COMMENT OUT) THE CALL TO SFCDIF IN ROUTINE SFLX.
!
!   Z0 and CZIL:
!
!   THE ROUGHNESS LENGTH PARAMETERS "Z0" AND "CZIL" MUST BE SET HERE IN THE
!   DRIVER TO SUPPORT THE "OPTION-A", I.E. THE CALL TO SFCDIF BELOW.  IN SO
!   DOING, THE "Z0" AND "CZIL" ASSIGNED HERE MUST CORRESPOND TO THEIR
!   VALUES, CALLED BY SFLX JUST BEFORE CALL SFCDIF.
!   THUS THE VALUE OF "Z0" ASSIGNED HERE MUST CORRESPOND TO THAT ASSIGNED
!   FOR THE CHOSEN VEG CLASS THAT WAS ALREADY INPUT EARLIER IN THE DRIVER.
!
!   BECAUSE OF THE IMPLICIT ITERATIVE NATURE OF THE "PAULSON" SURFACE-LAYER
!   SCHEME USED IN ROUTINE SFCDIF, CH AND CM ARE CO-DEPENDENT.  SIMILARLY,
!   THE IMPLICIT NATURE OF THE SFCDIF SCHEME ALSO REQUIRES THAT FOR EITHER
!   OPTION A OR B, CH AND CM MUST BE INITIALIZED EARLIER IN THE DRIVER BEFORE
!   THE START OF THE TIME-STEP LOOP, AS WELL AS BE CARRIED FORWARD FROM
!   TIME STEP TO TIME STEP AS "STATE VARIABLES", BECAUSE THE VALUES OF
!   CH AND CM FROM A PREVIOUS TIME STEP REPRESENT THE FIRST-GUESS VALUES FOR
!   THE CALL TO SFCDIF IN THE PRESENT TIME STEP.
!
!   SOME USERS MAY CHOOSE TO EXECUTE AN ENTIRELY DIFFERENT SCHEME IN PLACE OF
!   ROUTINE SFCDIF HERE, E.G. AN EXPLICIT SCHEME SUCH AS LOUIS (1979) THAT
!   EMPLOYS NO ITERATION AND HAS NO REQUIREMENT TO CARRY CH AND CM FORWARD
!   AS STATE VARIABLES FROM TIME STEP TO TIME STEP.  IN THAT CASE, IN
!   OPTION A, THE ROUTINE SHOULD BE CALLED HERE IN THE DRIVER AFTER ALL
!   NECESSARY INPUT ARGUMENTS FOR IT ARE DEFINED AT THIS POINT, OR CALLED IN
!   ROUTINE SFLX, AT THE POINT SFCDIF IS CALLED.
!
!      CALL SFCDIF ( Z, Z0, T1V, TH2V, SFCSPD,CZIL, CM, CH )
!
! ---------------------------------------------------------------------|
! INITIALIZE CH, CM (NOTE: initial these before time loop)
!      CH=1.E-4
!      CM=1.E-4
! 1998 May 22 0030 (Julian= 142) typical values initialization
!      CH=  0.0150022404
!      CM=  0.0205970779
! **NOTE: TRYING THESE VALUES AS TEST! 
! ---------------------------------------------------------------------|

!=== MAIN CALL TO LAND-SURFACE PHYSICS  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

! NOAH(T)%CH=  1.0E-4
! NOAH(T)%CM=  1.0E-4

! NOAH(T)%CH=  0.0150022404
! NOAH(T)%CM=  0.0205970779

  NOAH(T)%CH=  noah(t)%FORCING(13)
  NOAH(T)%CH=  MAX(NOAH(T)%CH, 1.0E-4)
  NOAH(T)%CM=  noah(t)%FORCING(13)
  NOAH(T)%CM=  MAX(NOAH(T)%CM, 1.0E-4)
! ---------------------------------------------------------------------|
! NEW FOR NOAH 2.7.1
! ---------------------------------------------------------------------|
!--  Determine Precipitation Type Before Call to SFLX (noah_physics.F90)
      FFROZP = 0.0
      IF (PRCP .GT. 0.0) THEN
        IF (SFCTMP .LE. T0) THEN
           FFROZP = 1.0
        ENDIF
      ENDIF

!--  Determine Net Incoming Solar
!JESSE 20050321 SNCOVR NOT A STATE VARIABLE, CALCULATED IN SFLX.
     ! IF (NOAH(T)%SNEQV .EQ. 0.0) THEN
     !   ALBEDO = ALB
     ! ELSE
     !   ALBEDO = ALB + SNCOVR*(SNOALB-ALB)
     !   IF (ALBEDO .GT. SNOALB) ALBEDO=SNOALB
     ! ENDIF
     !
     ! SOLNET = SOLDN*(1.0-ALBEDO)

     ALB = noah(t)%FORCING(10) * 0.01
     ALB = MAX(ALB, 0.05)
     ALB = MIN(ALB, 0.95)
     ALBEDO = ALB
     SNCOVR = 0.
!    SOLNET = 0.
     SOLNET = SOLDN*(1.0-ALBEDO)

! ---------------------------------------------------------------------|
! QC FOR SNOW PROPERTIES. JESSE 20050106
! ---------------------------------------------------------------------|
      IF ( NOAH(T)%SNEQV .EQ. 0.0 ) THEN
           NOAH(T)%SNOWH = 0.0
      ELSE
         IF ( NOAH(T)%SNOWH .EQ. 0.0 ) THEN
             NOAH(T)%SNOWH  = NOAH(T)%SNEQV * 10.
         ENDIF
      ENDIF 

! ---------------------------------------------------------------------|
! RESET FLUXES BEFORE SFLX
! ---------------------------------------------------------------------|

 ice = 0
 fup = 0.
 eta = 0.
 ec  = 0.
 et  = 0.
 ett = 0.
 edir  = 0.
 esnow = 0.
 etp   = 0.
 evp   = 0.
 beta  = 0.
 shtflx = 0.
 gflx = 0.
 flx1 = 0.
 flx2 = 0.
 flx3 = 0.
 runoff1 = 0.
 runoff2 = 0.
 runoff3 = 0.

 rc = 0.
 pc = 0.
 rcs= 0.
 rct= 0.
 rcq= 0.
 rcsoil = 0.

 MSTAVRZ = 0.
 MSTAVTOT= 0.
 SOILM   = 0.
 DRIP    = 0.
 DEW     = 0.
 SNOMLT  = 0.

 res = 0.

 IF(T==C1) THEN
      WRITE(*,*) iam, 'J---NOAH_MAIN BEFORE SFLX---------------'
      WRITE(*,*) iam, '  --------------------------------------'
      WRITE(*,*) iam, '  State Variables '
      WRITE(*,*) iam, '  --------------------------------------'
      WRITE(*,*) DT,' DT'
      WRITE(*,*) 'TILE ', T
      WRITE(*,*) 'FFROZP,ICE,DT,Z,NSOIL,SLDPTH'
      WRITE(*,*)  FFROZP,ICE,DT,Z,NSOIL,SLDPTH
      WRITE(*,*) 'LWDN,SOLDN,SOLNET,SFCPRS,PRCP,SFCTMP,Q2,SFCSPD'
      WRITE(*,*)  LWDN,SOLDN,SOLNET,SFCPRS,PRCP,SFCTMP,Q2,SFCSPD
      WRITE(*,*) 'TH2,Q2SAT,DQSDT2'
      WRITE(*,*)  TH2,Q2SAT,DQSDT2
      WRITE(*,*) 'SLOPE,SHDFAC,SHDMIN,SHDMAX,PTU,ALB,SNOALB'
      WRITE(*,*)  SLOPE,SHDFAC,SHDMIN,SHDMAX,PTU,ALB,SNOALB
      WRITE(*,*) 'RSMIN,RGL,HS,SNUP,Z0,XLAI,NROOT'
      WRITE(*,*)  RSMIN,RGL,HS,SNUP,Z0,XLAI,NROOT
      WRITE(*,*) 'PSISAT,BEXP,DKSAT,SMCMAX,QUARTZ,DWSAT'
      WRITE(*,*)  PSISAT,BEXP,DKSAT,SMCMAX,QUARTZ,DWSAT
      WRITE(*,*) 'SMCWLT,SMCREF,SMCDRY,F1,KDT,FRZX,FRZFACT,TBOT'
      WRITE(*,*)  SMCWLT,SMCREF,SMCDRY,F1,KDT,FRZX,FRZFACT,TBOT
      WRITE(*,*) 'NOAH(T)%CMC,NOAH(T)%T1'
      WRITE(*,*)  NOAH(T)%CMC,NOAH(T)%T1
      WRITE(*,*) 'STC  ',(NOAH(T)%STC(IJ), IJ=1,NSOIL)
      WRITE(*,*) 'SMC  ',(NOAH(T)%SMC(IJ), IJ=1,NSOIL)
      WRITE(*,*) 'SH20 ',(NOAH(T)%SH2O(IJ), IJ=1,NSOIL)
      WRITE(*,*) 'NOAH(T)%SNOWH,NOAH(T)%SNEQV,ALBEDO,NOAH(T)%CH,NOAH(T)%CM'
      WRITE(*,*)  NOAH(T)%SNOWH,NOAH(T)%SNEQV,ALBEDO,NOAH(T)%CH,NOAH(T)%CM
      WRITE(*,*) 'EVP,ETA,SHTFLX,EC,EDIR'
      WRITE(*,*)  EVP,ETA,SHTFLX,EC,EDIR
      WRITE(*,*) 'ET   ',(ET(IJ), IJ=1,NSOIL)
      WRITE(*,*) 'ETT,ESNOW,DRIP,DEW,BETA,ETP'
      WRITE(*,*)  ETT,ESNOW,DRIP,DEW,BETA,ETP
      WRITE(*,*) 'GFLX,FLX1,FLX2,FLX3,SNOMLT,SNCOVR'
      WRITE(*,*)  GFLX,FLX1,FLX2,FLX3,SNOMLT,SNCOVR
      WRITE(*,*) 'RUNOFF1,RUNOFF2,RUNOFF3'
      WRITE(*,*)  RUNOFF1,RUNOFF2,RUNOFF3
      WRITE(*,*) 'RC,PC,RCS,RCT,RCQ,RCSOIL'
      WRITE(*,*)  RC,PC,RCS,RCT,RCQ,RCSOIL
      WRITE(*,*) 'MSTAVRZ,MSTAVTOT,SOILM'
      WRITE(*,*)  MSTAVRZ,MSTAVTOT,SOILM
      WRITE(*,*) '----------------------------------------'
 ENDIF

!*** Noah 2.7.1

 IF ( noah(t)%VEGT .NE. 15.) THEN !IGBP SNOW AND ICE
! IF ( noah(t)%VEGT .NE. 13.) THEN !SIB GLACIAL
!     CALL SFLX (T,int(NOAH(T)%VEGT),&
!      FFROZP,ICE,DT,Z,NSOIL,SLDPTH,&
!      LWDN,SOLDN,SOLNET,SFCPRS,PRCP,SFCTMP,Q2,SFCSPD, &
!      TH2,Q2SAT,DQSDT2,&
!      SLOPE,SHDFAC,SHDMIN,SHDMAX,PTU,ALB,SNOALB, &
!      RSMIN,RGL,HS,SNUP,Z0,XLAI,NROOT,&
!      PSISAT,BEXP,DKSAT,SMCMAX,QUARTZ,DWSAT, &
!      SMCWLT,SMCREF,SMCDRY,F1,KDT,FRZX,FRZFACT,TBOT, &
!      NOAH(T)%CMC,NOAH(T)%T1,NOAH(T)%STC,NOAH(T)%SMC,NOAH(T)%SH2O, &
!      NOAH(T)%SNOWH,NOAH(T)%SNEQV,ALBEDO,NOAH(T)%CH,NOAH(T)%CM,&
!      EVP,ETA,SHTFLX, &
!      EC,EDIR,ET,ETT,ESNOW,DRIP,DEW, &
!      BETA,ETP,GFLX, &
!      FLX1,FLX2,FLX3,&
!      SNOMLT,SNCOVR,&
!      RUNOFF1,RUNOFF2,RUNOFF3, &
!      RC,PC,RCS,RCT,RCQ,RCSOIL, &
!      MSTAVRZ,MSTAVTOT,SOILM)

!*** Noah 2.7GFS
       couple = 0
       sfcems=1.
       ivegsrc=1
       bexpp=0
       xlaip=0
       lheatstrg=.false.
       slopetyp=1
      call sflx (nsoil, couple, ice, ffrozp, dt, z, sldpth,&
        soldn, solnet, lwdn, sfcems, sfcprs, sfctmp,&
        sfcspd, prcp, q2, q2sat, dqsdt2, th2, ivegsrc,&
        INT(noah(t)%vegt),soiltyp, slopetyp, shdmin, alb, snoalb,&
        bexpp, xlaip,&
        lheatstrg,shdmax,&
        tbot, noah(t)%cmc, noah(t)%t1, noah(t)%stc, noah(t)%smc,&
        noah(t)%sh2o, noah(t)%sneqv, noah(t)%ch, noah(t)%cm, z0,&
        nroot, shdfac, noah(t)%snowh, albedo, eta, shtflx, ec,&
        edir, et, ett, esnow, drip, dew, beta, etp, gflx,&
        flx1, flx2, flx3, runoff1, runoff2, runoff3,&
        snomlt, sncovr, rc, pc, rsmin, xlai, rcs, rct, rcq,&
        rcsoil,soilw,soilm, smcwlt, smcdry, smcref,smcmax)
 ELSE 
       NOAH(T)%SMC  = 1.0
       NOAH(T)%SH2O = 0.0
       NOAH(T)%SNEQV = 0.1
       NOAH(T)%SNOWH = 1.0
 ENDIF
!      write(71,*)nsoil, couple, ice, ffrozp, dt, z, sldpth
!      write(72,*)soldn, solnet, lwdn, sfcems, sfcprs, sfctmp
!      write(73,*)sfcspd, prcp, q2, q2sat, dqsdt2, th2, ivegsrc
!      write(74,*)INT(noah(t)%vegt),soiltyp, slopetyp, shdmin, alb, snoalb
!      write(75,*)bexpp, xlaip,lheatstrg,shdmax
!      write(76,*)tbot, noah(t)%cmc, noah(t)%t1, noah(t)%stc, noah(t)%smc
!      write(77,*)noah(t)%sh2o, noah(t)%sneqv, noah(t)%ch, noah(t)%cm, z0
!      write(78,*)nroot, shdfac, noah(t)%snowh, albedo, eta, shtflx, ec
!      write(79,*)edir, et, ett, esnow, drip, dew, beta, etp, gflx
!      write(80,*)flx1, flx2, flx3, runoff1, runoff2, runoff3
!      write(81,*)snomlt, sncovr, rc, pc, rsmin, xlai, rcs, rct, rcq
!      write(82,*)rcsoil,soilw,soilm, smcwlt, smcdry, smcref,smcmax
!      stop

!*** Noah 2.6

     ! CALL SFLX (T,&
     !  ICE,DT,Z,NSOIL,SLDPTH,&
     !  LWDN,SOLDN,SFCPRS,PRCP,SFCTMP,Q2,SFCSPD, &
     !  TH2,Q2SAT,DQSDT2,&
     !  SLOPE,SHDFAC,SHDMIN,PTU,ALB,SNOALB, &
     !  RSMIN,RGL,HS,SNUP,Z0,XLAI,NROOT,&
     !  PSISAT,BEXP,DKSAT,SMCMAX,QUARTZ,DWSAT, &
     !  SMCWLT,SMCREF,SMCDRY,F1,KDT,FRZX,FRZFACT,TBOT, &
     !  NOAH(T)%CMC,NOAH(T)%T1,NOAH(T)%STC,NOAH(T)%SMC,NOAH(T)%SH2O, &
     !  NOAH(T)%SNOWH,NOAH(T)%SNEQV,ALBEDO,NOAH(T)%CH,NOAH(T)%CM,&
     !  EVP,ETA,SHTFLX, &
     !  EC,EDIR,ET,ETT,ESNOW,DRIP,DEW, &
     !  BETA,ETP,GFLX, &
     !  FLX1,FLX2,FLX3,&
     !  SNOMLT,SNCOVR,&
     !  RUNOFF1,RUNOFF2,RUNOFF3, &
     !  RC,PC,RCS,RCT,RCQ,RCSOIL, &
     !  MSTAVRZ,MSTAVTOT,SOILM)

 IF(T==C1) THEN
      PRINT*,'J---DONE SFLX---------------------------'
 ENDIF

!******************************************************************
!   CALCULATE UPWARD LONGWAVE RAD USING UPDATED SKIN TEMPERATURE

      T14 = noah(t)%T1 * noah(t)%T1 * noah(t)%T1 * noah(t)%T1 
!      FUP = 5.67E-8 * T14
      FUP = 5.67E-8 * T14 * (0.95*SNCOVR + 1.00*(1.0-SNCOVR))

!   CALCULATE SNOW DENSITY FROM OUTPUT:
      IF (NOAH(T)%SNEQV .GT. 0.0) THEN
        IF (NOAH(T)%SNOWH .LE. 0.0) NOAH(T)%SNOWH = NOAH(T)%SNEQV * 10.
        SNDENS=NOAH(T)%SNEQV/NOAH(T)%SNOWH
      ELSE
        NOAH(T)%SNOWH=0.0
        SNDENS=0.0
      ENDIF

!   CALCULATE RESIDUAL OF ALL SURFACE ENERGY BALANCE EQN TERMS.
!JESSE 20050321 SIGN CONVENTION FOR HEAT FLUX (+) AWAY SFC (-) INTO SFC
      GFLX = -GFLX
      F = SOLDN*(1.0-ALBEDO) + LWDN
      RES    = F - SHTFLX - GFLX - ETA - FUP - FLX1 - FLX2 - FLX3

!   SET LOWER BOUND OF SMC(4) FOR SSiB VTYPE=1 (TROPICAL FOREST)
!                                 IGBP VTYPE=2 (TROPICAL FOREST)
!JESSE 20080201, 20130801

!     IF( NOAH(T)%VEGT .EQ. 2. ) THEN
!      IF( NOAH(T)%VEGT .EQ. 1. ) THEN
!         IF( NOAH(T)%SMC(4) .LT. 0.27 ) THEN
!             NOAH(T)%SH2O(4) = NOAH(T)%SH2O(4) / NOAH(T)%SMC(4) * 0.27
!             RUNOFF2 = RUNOFF2 - (0.27-NOAH(T)%SMC(4)) * SLDPTH(4) / DT
!             NOAH(T)%SMC(4) = 0.27
!         ENDIF
!     ENDIF   

  IF(T==C1) THEN
      WRITE(*,*) iam, 'J---NOAH_MAIN AFTER SFLX ---------------'
      WRITE(*,*) iam, '  --------------------------------------'
      WRITE(*,*) iam, '  State Variables '
      WRITE(*,*) iam, '  --------------------------------------'
      WRITE(*,*) DT,' DT'
      WRITE(*,*) 'TILE ', T
      WRITE(*,*) 'FFROZP,ICE,DT,Z,NSOIL,SLDPTH'
      WRITE(*,*)  FFROZP,ICE,DT,Z,NSOIL,SLDPTH
      WRITE(*,*) 'LWDN,SOLDN,SOLNET,SFCPRS,PRCP,SFCTMP,Q2,SFCSPD'
      WRITE(*,*)  LWDN,SOLDN,SOLNET,SFCPRS,PRCP,SFCTMP,Q2,SFCSPD
      WRITE(*,*) 'TH2,Q2SAT,DQSDT2'
      WRITE(*,*)  TH2,Q2SAT,DQSDT2
      WRITE(*,*) 'SLOPE,SHDFAC,SHDMIN,SHDMAX,PTU,ALB,SNOALB'
      WRITE(*,*)  SLOPE,SHDFAC,SHDMIN,SHDMAX,PTU,ALB,SNOALB
      WRITE(*,*) 'RSMIN,RGL,HS,SNUP,Z0,XLAI,NROOT'
      WRITE(*,*)  RSMIN,RGL,HS,SNUP,Z0,XLAI,NROOT
      WRITE(*,*) 'PSISAT,BEXP,DKSAT,SMCMAX,QUARTZ,DWSAT'
      WRITE(*,*)  PSISAT,BEXP,DKSAT,SMCMAX,QUARTZ,DWSAT
      WRITE(*,*) 'SMCWLT,SMCREF,SMCDRY,F1,KDT,FRZX,FRZFACT,TBOT'
      WRITE(*,*)  SMCWLT,SMCREF,SMCDRY,F1,KDT,FRZX,FRZFACT,TBOT
      WRITE(*,*) 'NOAH(T)%CMC,NOAH(T)%T1'
      WRITE(*,*)  NOAH(T)%CMC,NOAH(T)%T1
      WRITE(*,*) 'STC  ',(NOAH(T)%STC(IJ), IJ=1,NSOIL)
      WRITE(*,*) 'SMC  ',(NOAH(T)%SMC(IJ), IJ=1,NSOIL)
      WRITE(*,*) 'SH20 ',(NOAH(T)%SH2O(IJ), IJ=1,NSOIL)
      WRITE(*,*) 'NOAH(T)%SNOWH,NOAH(T)%SNEQV,ALBEDO,NOAH(T)%CH,NOAH(T)%CM'
      WRITE(*,*)  NOAH(T)%SNOWH,NOAH(T)%SNEQV,ALBEDO,NOAH(T)%CH,NOAH(T)%CM
      WRITE(*,*) 'EVP,ETA,SHTFLX,EC,EDIR'
      WRITE(*,*)  EVP,ETA,SHTFLX,EC,EDIR
      WRITE(*,*) 'ET   ',(ET(IJ), IJ=1,NSOIL)
      WRITE(*,*) 'ETT,ESNOW,DRIP,DEW,BETA,ETP'
      WRITE(*,*)  ETT,ESNOW,DRIP,DEW,BETA,ETP
      WRITE(*,*) 'GFLX,FLX1,FLX2,FLX3,SNOMLT,SNCOVR'
      WRITE(*,*)  GFLX,FLX1,FLX2,FLX3,SNOMLT,SNCOVR
      WRITE(*,*) 'RUNOFF1,RUNOFF2,RUNOFF3'
      WRITE(*,*)  RUNOFF1,RUNOFF2,RUNOFF3
      WRITE(*,*) 'RC,PC,RCS,RCT,RCQ,RCSOIL'
      WRITE(*,*)  RC,PC,RCS,RCT,RCQ,RCSOIL
      WRITE(*,*) 'MSTAVRZ,MSTAVTOT,SOILM'
      WRITE(*,*)  MSTAVRZ,MSTAVTOT,SOILM
      WRITE(*,*) '========================================'
  !    WRITE(82,'(5F10.4)') RC, RCS, RCT, RCQ, RCSOIL
  !    WRITE(83,'(8F10.4)') EDIR, EC, ETT, ESNOW, (ET(IJ), IJ=1,NSOIL)
  ENDIF

!******************************************************************
!=== Collect the output variables into NOAH(T)%RETURN
  !IF(T==C1) PRINT*,"energy"
      noah(t)%swnet = noah(t)%swnet+soldn*(1.0-albedo)
  !    noah(t)%lwnet = noah(t)%lwnet+(5.67E-8)*(NOAH(T)%T1**4.0)-LWDN
      noah(t)%lwnet = noah(t)%lwnet+FUP-LWDN
      noah(t)%qle = noah(t)%qle+eta
      noah(t)%qh = noah(t)%qh+shtflx
      noah(t)%qg = noah(t)%qg-gflx
      
  !IF(T==C1) PRINT*,"water"

      if (sfctmp .le. t0) then
         noah(t)%snowf = noah(t)%snowf+prcp
         noah(t)%rainf = noah(t)%rainf+0.0
      else
         noah(t)%snowf = noah(t)%snowf+0.0
         noah(t)%rainf = noah(t)%rainf+prcp
      endif
      noah(t)%evap = noah(t)%evap+evp
      noah(t)%qs = noah(t)%qs+runoff1*1000.0
      noah(t)%qsb = noah(t)%qsb+ runoff2*1000.0
      noah(t)%qsm = noah(t)%qsm+ snomlt*1000.0

  !IF(T==C1) PRINT*,"surface"

      NOAH(T)%avgsurft=NOAH(T)%T1
      NOAH(T)%albedo=ALBEDO
!JESSE 20050127 MAKE SWE INSTANENOUS VARIABLE
      !noah(t)%swe = noah(t)%swe + noah(t)%sneqv*1000.0
      noah(t)%swe = noah(t)%sneqv*1000.0 

  !IF(T==C1) PRINT*,"soil"

! JESSE soil moisture is instantaneous in [mm]
!      NOAH(T)%soilmoist1 =noah(t)%soilmoist1+NOAH(T)%SMC(1)*1000.0*SLDPTH(1)
!      NOAH(T)%soilmoist2 =noah(t)%soilmoist2+NOAH(T)%SMC(2)*1000.0*SLDPTH(2)
!      NOAH(T)%soilmoist3 =noah(t)%soilmoist3+NOAH(T)%SMC(3)*1000.0*SLDPTH(3)
!      NOAH(T)%soilmoist4 =noah(t)%soilmoist4+NOAH(T)%SMC(4)*1000.0*SLDPTH(4)
      NOAH(T)%soilmoist1 =NOAH(T)%SMC(1)*1000.0*SLDPTH(1)
      NOAH(T)%soilmoist2 =NOAH(T)%SMC(2)*1000.0*SLDPTH(2)
      NOAH(T)%soilmoist3 =NOAH(T)%SMC(3)*1000.0*SLDPTH(3)
      NOAH(T)%soilmoist4 =NOAH(T)%SMC(4)*1000.0*SLDPTH(4)
      
!      NOAH(T)%soilwet =noah(t)%soilwet+MSTAVTOT
      NOAH(T)%soilwet = MSTAVTOT
!      NOAH(T)%ecanop = noah(t)%ecanop + ec*1000.0
!      NOAH(T)%tveg = noah(t)%tveg+ETT*1000.0
!      NOAH(T)%esoil = noah(t)%esoil+EDIR*1000.0
! JESSE EC/ETT/EDIR in [W m-2]
      NOAH(T)%ecanop = noah(t)%ecanop + ec
      NOAH(T)%tveg = noah(t)%tveg + ETT
      NOAH(T)%esoil = noah(t)%esoil + EDIR
      noah(T)%canopint = noah(t)%cmc*1000.0

! ROOT ZONE COLUMN SOIL MOISTURE IN METERS (SOILRZ)
      soilrz = 0.
      do k = 1,nroot
         soilrz = soilrz+(noah(t)%smc(k)*sldpth(k)*1000.0)
      end do
!      noah(t)%rootmoist= noah(t)%rootmoist+soilrz
      noah(t)%rootmoist = soilrz

!      if(lis%t%tscount == 0 .or. lis%t%tscount ==1) then 
      if(lis%t%tscount == 0 .or. lis%t%tscount ==1 &
           .or.lis%f%rstflag.eq.1) then
   
        noah(t)%soilm_prev = noah(t)%soilmoist1 + noah(t)%soilmoist2 &
                           + noah(t)%soilmoist3 + noah(t)%soilmoist4
        noah(t)%swe_prev = noah(t)%swe
      endif
      
      noah(t)%count=noah(t)%count+1
      
      enddo 

! ---------------------------------------------------------------------|
! OBS SNOW UPDATE. JESSE 20051119
! ---------------------------------------------------------------------|
!      if( lis%t%gmt .EQ. 0.0 ) then
!        CALL noah_snowupdate()
!      endif
! ---------------------------------------------------------------------|
 
  if(masterproc) PRINT*,"J---NOAH_MAIN(",iam,") END ---------------------------"
      return
!BOC
    end subroutine noah_main


!*** NOAH FUNCTIONS ****************************************************

      FUNCTION DQS (T)

      use machine ,   only : kind_phys
      IMPLICIT NONE

!
!  PURPOSE:  TO CALCULATE VALUES OF VAPOR PRESSURE (E)
!            AND P * DQS/DT (P TIMES CHG IN SAT MXG RATIO WITH RESPECT
!            TO THE CHG IN TEMP) IN SUBSTITUTION TO THE LOOK-UP TABLES.
!
!            FORMULAS AND CONSTANTS FROM ROGERS AND YAU, 1989.
!                         ADDED BY PABLO J. GRUNMANN, 6/30/97.
!
      REAL(KIND=KIND_PHYS):: DESDT
      REAL(KIND=KIND_PHYS):: DQS
!    REAL(KIND=KIND_PHYS):: ESD
      REAL(KIND=KIND_PHYS):: LW
      REAL(KIND=KIND_PHYS):: T
      REAL(KIND=KIND_PHYS):: ES

!      REAL(KIND=KIND_PHYS), PARAMETER:: CP = 1005.
!      REAL(KIND=KIND_PHYS), PARAMETER:: CV = 718.
!      REAL(KIND=KIND_PHYS), PARAMETER:: CVV = 1410.
      REAL(KIND=KIND_PHYS), PARAMETER:: CPV = 1870.
      REAL(KIND=KIND_PHYS), PARAMETER:: RV = 461.5
      REAL(KIND=KIND_PHYS), PARAMETER:: CW = 4187.
      REAL(KIND=KIND_PHYS), PARAMETER:: EPS = 0.622
      REAL(KIND=KIND_PHYS), PARAMETER:: ESO = 611.2
      REAL(KIND=KIND_PHYS), PARAMETER:: TO = 273.15
      REAL(KIND=KIND_PHYS), PARAMETER:: LVH2O = 2.501000E+6


!     ABOUT THE PARAMETERS:
!
!     EPS ---------- WATER - DRY AIR MOLECULAR MASS RATIO, EPSILON
!
!   VALUES FOR SPECIFIC HEAT CAPACITY AND INDIVIDUAL GAS CONSTANTS
!   IN [JOULES/(KG*KELVIN)] UNITS.
!
!     DRY AIR:
!             CP, CV
!     WATER VAPOR:
!                 CVV = 1410.
!                 CPV = 1870.
!                 RV  =  461.5
!     LIQUID WATER:
!                  CW = 4187.
!
!     ESO = ES(T=273.15 K) = SAT. VAPOR PRESSURE (IN PASCAL) AT T=TO
!      TO = 273.15
!
!     SAT. MIXING  RATIO: QS ~= EPS*ES/P
!     CLAUSIUS-CLAPEYRON: DES/DT = L*ES/(RV*T^2)
!     @QS/@T =  (EPS/P)*DES/DT

          LW = LVH2O - ( CW - CPV ) * ( T - TO )
          ES = ESO*EXP (LW*(1/TO - 1/T)/RV)
          DESDT = LW*ES/(RV*T*T)

!    FOR INSERTION IN DQSDT FUNCTION:
!    DQSDT = DQS/P , WHERE DQS = EPS*DESDT

          DQS = EPS*DESDT

          RETURN
          END

!----------------------------------------------------------------------

      FUNCTION DQSDT ( SFCTMP, SFCPRS )

  use machine ,   only : kind_phys
      IMPLICIT NONE

!
!    PURPOSE:  TO RETRIEVE THE APPROPRIATE VALUE OF DQSDT (THE CHANGE
!    =======   OF THE SATURATION MIXING RATIO WITH RESPECT TO THE
!              CHANGE IN TEMPERATURE) FROM:
!
!              FORMULAS INTRODUCED IN FUNCTION DQS
!                                  (MODIFIED BY PABLO GRUNMANN, 7/9/97).
!

      REAL(KIND=KIND_PHYS):: SFCTMP
      REAL(KIND=KIND_PHYS):: SFCPRS
      REAL(KIND=KIND_PHYS):: DQS
      REAL(KIND=KIND_PHYS):: DQSDT

      IF ((SFCTMP .GE. 173.0) .AND. (SFCTMP  .LE.  373.0)) THEN

!  IF THE INPUT SFC AIR TEMP IS BTWN 173 K AND 373 K, USE
!   FUNCTION DQS TO DETERMINE THE SLOPE OF SAT.MIX RATIO FUNCTION

        DQSDT = DQS (SFCTMP) / SFCPRS

      ELSE

!  OTHERWISE, SET DQSDT EQUAL TO ZERO

        DQSDT = 0.0

      END IF

      RETURN
      END

!---------------------------------------------------------------

      FUNCTION E(T)

  use machine ,   only : kind_phys
      IMPLICIT NONE

!
!  PURPOSE:  TO CALCULATE VALUES OF SAT. VAPOR PRESSURE (E)
!            FORMULAS AND CONSTANTS FROM ROGERS AND YAU, 1989.
!                         ADDED BY PABLO J. GRUNMANN, 7/9/97.
!

      REAL(KIND=KIND_PHYS):: LW
      REAL(KIND=KIND_PHYS):: T
      REAL(KIND=KIND_PHYS):: E

!      REAL(KIND=KIND_PHYS), PARAMETER:: EPS = 0.622 
!      REAL(KIND=KIND_PHYS), PARAMETER:: CP = 1005.
!      REAL(KIND=KIND_PHYS), PARAMETER:: CV = 718.
!      REAL(KIND=KIND_PHYS), PARAMETER:: CVV = 1410.
      REAL(KIND=KIND_PHYS), PARAMETER:: CPV = 1870.
      REAL(KIND=KIND_PHYS), PARAMETER:: RV = 461.5
      REAL(KIND=KIND_PHYS), PARAMETER:: CW = 4187.
      REAL(KIND=KIND_PHYS), PARAMETER:: ESO = 611.2
      REAL(KIND=KIND_PHYS), PARAMETER:: TO = 273.15
      REAL(KIND=KIND_PHYS), PARAMETER:: LVH2O = 2.501000E+6

!   ABOUT THE PARAMETERS:
!
!    EPS --- WATER - DRY AIR MOLECULAR MASS RATIO, EPSILON
!
!    VALUES FOR SPECIFIC HEAT CAPACITY AND INDIVIDUAL GAS CONSTANTS
!    IN [JOULES/(KG*KELVIN)] UNITS.
!
!     DRY AIR:
!             CP, CV
!     WATER VAPOR:
!             CVV = 1410.
!             CPV = 1870.
!             RV  =  461.5
!     LIQUID WATER:
!             CW = 4187.
!
!     ESO = ES(TO) = SAT. VAPOR PRESSURE (IN PASCAL) AT T=TO
!      TO = 273.15
!
!     CLAUSIUS-CLAPEYRON: DES/DT = L*ES/(RV*T^2)

          LW = LVH2O - ( CW - CPV ) * ( T - TO )
          E = ESO*EXP (LW*(1/TO - 1/T)/RV)

          RETURN
          END


!CC 1. DRIVER SUBROUTINE ==> SUBROUTINE OBTLWDN CCCCCCCCCCCCCCCCC

!      SUBROUTINE OBTLWDN(SFCTMP,LWDN)

!                      RADIATION
!
! The following step (OBTENTION OF LWDN) is used if
! user wants to calculate longwave downward.
!
! OBTENTION OF LWDN <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
!
! COMPUTATION OF LWDN (INCOMING LW RADIATION) FROM TAIR AND Q:
!
!...............LWDN = EMISS*SIGMA*(TAK)^4.
!
! WHERE:   TAK = AIR TEMP IN KELVIN
!        EMISS = 0.7  OR  (IDSO AND JACKSON, 1969):
!
!        EMISS = (1 - 0.261 EXP(-7.77*10^(-4)X(273-TAK)^2)
!
!      NEED STEFAN-BOLTZMANN CONSTANT, SIGMA
!         SIGMA = 5.672 * 10^-8  W M^-2 T^-4
!
!           SIGMA = 5.672E-8
!           TAK = SFCTMP
!           EMISS = 1 - 0.261*EXP((-7.77E-4)*(273-TAK)^2.)
!
!           LWDN = EMISS*SIGMA*TAK^4.
!
!        RETURN
!        END

!CCCC  END OF DRIVER SUBROUTINES CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
