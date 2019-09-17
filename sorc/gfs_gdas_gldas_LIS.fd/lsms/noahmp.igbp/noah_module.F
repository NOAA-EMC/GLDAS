!-------------------------------------------------------------------------
! NASA Goddard Space Flight Center Land Information System (LIS) V3.0
! Released May 2004
!
! See SOFTWARE DISTRIBUTION POLICY for software distribution policies
!
! The LIS source code and documentation are in the public domain,
! available without fee for educational, research, non-commercial and
! commercial purposes.  Users may distribute the binary or source
! code to third parties provided this statement appears on all copies and
! that no charge is made for such copies.
!
! NASA GSFC MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE
! SOFTWARE FOR ANY PURPOSE.  IT IS PROVIDED AS IS WITHOUT EXPRESS OR
! IMPLIED WARRANTY.  NEITHER NASA GSFC NOR THE US GOVERNMENT SHALL BE
! LIABLE FOR ANY DAMAGES SUFFERED BY THE USER OF THIS SOFTWARE.
!
! See COPYRIGHT.TXT for copyright details.
!
!-------------------------------------------------------------------------
!BOP
!
! !MODULE: noah_module.F90
!
! !DESCRIPTION:
!  Module for 1-D NOAH land model driver variable specification.
!
! !REVISION HISTORY:
!
! 28 Apr 2002: K. Arsenault added NOAH LSM 2.5 code to LDAS. 
! 14 Nov 2002: Sujay Kumar Optimized version for LIS  
! 12 Apr 2006: Jesse Meng Added Z0, FORCING(11:16)
!              When changing number of variables, MUST
!              modify noah_blkcnts=(/I,J/) in noahpardef_module.F
!              I = number of integer; J = number of real
! 
! 02 Jul 2019: Youlong Xia modified for NoahMP model
! !INTERFACE:
module noah_module
!EOP
  implicit none
  public noahdec
!BOC
  type noahdec
     
     INTEGER :: ts                 !Timestep (seconds)
     INTEGER :: maxt               !Maximum tiles per grid
     INTEGER :: SIBVEG             !UMD to SIB Vegetation Class Index value
     INTEGER :: NSLAY              !Number of NOAH soil layers (4)
     INTEGER :: count
     INTEGER :: zobsoil(1)         !Zobler Soil Classes (LIS%NCH)
     
     REAL:: VEGP(7)      !Static vegetation parameter values, dim(NOAH_NVEGP)
     REAL:: VEGIP        !Interpolated Green Fraction from monthly parameters 
     REAL:: VEGMP1       !Month 1 Greenness Fraction Value 
     REAL:: VEGMP2       !Month 2 Greenness Fraction Value
     REAL:: ALBSF1       !Date 1 Snow-Free Albedo Value
     REAL:: ALBSF2       !Date 2 Snow-Free Albedo Value
     REAL:: SOILP(10)    !Static soil parameter values, dim(NOAH_NSOILP)
     REAL:: ALBSF        !Quarterly Snow-Free Albedo dataset
     REAL:: mxsnalb      !Maximum snow albedo dataset
     REAL:: tempbot      !Bottom boundary temperature
     REAL:: Z0           !Surface roughness [m]
!-------------------------------------------------------------------------
! NOAH and NOAHMP common state Variables
!-------------------------------------------------------------------------
     REAL :: tskin       !NOAH Skin Temperature (K)
     REAL :: canopy      !NOAH Canopy Water Content 
     REAL :: snwdph      !NOAH Actual Snow depth (m) 
     REAL :: weasd       !NOAH Water Equivalent Snow Depth (m)
     REAL :: stc(4)      !NOAH Soil Temperaure (4 layers)
     REAL :: smc(4)      !NOAH Soil (4 layers)
     REAL :: slc(4)      !NOAH Liquid-only soil moisture (4 layers)
     REAL :: chxy        !NOAH Heat/moisture exchange coef.
     REAL :: cmxy        !NOAH Momentum exchange coef.
     REAL :: zorl        ! roughness length
     REAL :: FORCING(16) !TILE FORCING..
     REAL :: vegt        !Vegetation type of tile
     REAL :: srflag      ! rain-snow flag
! NOAHMP-State variable only 
     REAL :: tprcp        ! total precipitation [mm] 
     REAL :: trans        ! transpiration [w/m2]
     REAL :: tsurf        ! land surface radiation T [k]
     REAL :: snowxy       ! actual no. of snow layers [-]
     REAL :: tvxy         ! vegetation temperature [k]
     REAL :: tgxy         ! ground temperature [k]
     REAL :: canicexy     ! intercepted ice mass [mm]
     REAL :: canliqxy     ! intercepted liquid water [mm]
     REAL :: eahxy        ! canopy air vapor pressure [pa]
     REAL :: tahxy        ! canopy air tmeperature [k]
     REAL :: fwetxy       ! wetted or snowed fraction of canopy [-]
     REAL :: sneqvoxy     ! snow mass at last time step [mm]
     REAL :: alboldxy     ! snow albedo at last time step [class type]
     REAL :: qsnowxy      ! snowfall [mm/s]
     REAL :: wslakexy     ! lake water storage (can be neg.) [mm]
     REAL :: zwtxy        ! depth to water table [m]
     REAL :: waxy         ! water storage in aquifer [mm]
     REAL :: wtxy         ! water in aquifer&saturated soil [mm]
     REAL :: tsnoxy(3)   ! snow/soil temperature [k]
     REAL :: zsnsoxy(7)  ! layer-bottom depth from snow surf [m]
     REAL :: snicexy(3)   ! snow layer ice [mm]
     REAL :: snliqxy(3)   ! snow layer liquid water [mm]
     REAL :: lfmassxy     ! leaf mass [g/m2]
     REAL :: rtmassxy     ! mass of fine roots [g/m2]
     REAL :: stmassxy     ! stem mass [g/m2]
     REAL :: woodxy       ! mass of wood (incl. woody roots) [g/m2]
     REAL :: stblcpxy     ! stable carbon in deep soil [g/m2]
     REAL :: fastcpxy     ! short-lived carbon, shallow soil [g/m2]
     REAL :: xlaixy       ! leaf area index [-]
     REAL :: xsaixy       ! stem area index [-]
     REAL :: taussxy      ! non-dimensional snow age
     REAL :: smoiseq(4)   ! equilibrium soil water  content [m3/m3]
     REAL :: smcwtdxy    ! soil water cont btw btm of soil and water tab [m3/m3]
     REAL :: deeprechxy   ! recharge to or from the water table when deep [m]
     REAL :: rechxy       ! recharge to or from the water tab when shallow [m]

!-----------------------------------------------------------------------
!  NOAH-Output variables
!-----------------------------------------------------------------------
     REAL :: snet 
     REAL :: lwnet
     REAL :: qle
     REAL :: qh
     REAL :: qg
     REAL :: snowf
     REAL :: rainf
     REAL :: evap
     REAL :: qs
     REAL :: qsb
     REAL :: qsm
     REAL :: avgsurft
     REAL :: albedo
     REAL :: swe
     REAL :: soilmoist1
     REAL :: soilmoist2
     REAL :: soilmoist3
     REAL :: soilmoist4
     REAL :: soilwet
     REAL :: ecanop
     REAL :: canopint
     REAL :: tveg
     REAL :: esoil
     REAL :: rootmoist
     REAL :: soilm_prev
     REAL :: swe_prev
  end type noahdec
!EOC
 end module noah_module


