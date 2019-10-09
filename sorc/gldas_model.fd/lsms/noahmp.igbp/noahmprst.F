!-------------------------------------------------------------------------
!     NASA GSFC Land Information Systems LIS 2.3                         !
!-------------------------------------------------------------------------
!BOP
!
! !ROUTINE: noahrst.F90
!
! !DESCRIPTION:
!  This program reads restart files for Noah.  This
!   includes all relevant water/energy storages, tile information,
!   and time information.  It also rectifies changes in the tile space.  
!
! !REVISION HISTORY:
!  1  Oct 1999: Jared Entin; Initial code
!  15 Oct 1999: Paul Houser; Significant F90 Revision
!  05 Sep 2001: Brian Cosgrove; Modified code to use Dag Lohmann's NOAA
!               initial conditions if necessary.  This is controlled with
!               local variable NOAAIC.  Normally set to 0 in this subroutine
!               but set to 1 if want to use Dag's NOAA IC's.  Changed output
!               directory structure, and commented out if-then check so that
!               directory is always made.
!  28 Apr 2002: Kristi Arsenault; Added NOAH LSM into LDAS
!  28 May 2002: Kristi Arsenault; For STARTCODE=4, corrected SNEQV values  
!                and put SMC, SH2O, STC limit for GDAS and GEOS forcing.
!
! RESTART FILE FORMAT(fortran sequential binary):
!  YR,MO,DA,HR,MN,SS,VCLASS,NCH !Restart time,Veg class,no.tiles, no.soil lay 
!  TILE(NCH)%COL        !Grid Col of Tile   
!  TILE(NCH)%ROW        !Grid Row of Tile
!  TILE(NCH)%FGRD       !Fraction of Grid covered by tile
!  TILE(NCH)%VEGT       !Vegetation Type of Tile
!  NOAH(NCH)%STATES     !Model States in Tile Space
! 
! !INTERFACE:
#include <misc.h>
subroutine noahrst
! !USES:
  use lisdrv_module, only : lis, grid, tile
  use noah_varder      ! NOAH tile variables
  use time_manager
  use tile_spmdMod
!EOP
  IMPLICIT NONE      
  
  INTEGER :: RW              ! 1=read restart, 2=write restart
  INTEGER :: C,R,T,I,J,L,N,F ! Loop counters
  INTEGER :: FOUND           ! Counting variable
  
  INTEGER :: YR,MO,DA,HR,MN,SS  !Time variables
  INTEGER :: VCLASS,NC,NR,NCH
  
  REAL :: RHOICE=917.0              ! Density of ice
  REAL :: WT1,WT2                   ! Weights for soil wetness initialization

  CHARACTER*80 FILEN,MKFYRMO
  CHARACTER*1  FNAME(80),FBASE(80),FSUBS(80),FMKDIR(80)
  CHARACTER*1  FTIME(10),FYRMODIR(80)
  INTEGER K
  INTEGER NOAAIC   ! 0=Use IC's from card file, 1=Use NOAA IC's from 
  
  integer :: curSec
  real, allocatable :: tmptile(:)
  PARAMETER (NOAAIC=0)

!=== End Variable Definition =============================================
!BOC
!-------------------------------------------------------------------------
! Read Active Archive File
!-------------------------------------------------------------------------
  if(masterproc) then 
     IF(LIS%O%STARTCODE.EQ.1)THEN
        allocate(tmptile(lis%d%nch))
        OPEN(40,FILE=noahdrv%NOAH_RFILE,FORM='unformatted')
        
        call timemgr_read_restart(40)
!3.1
!        call timemgr_restart()
!        call get_curr_date(lis%t%yr,lis%t%mo,lis%t%da,curSec)
!        call sec2time(curSec,lis%t%hr,lis%t%mn,lis%t%ss)
!        call updatetime(lis%t) !Updates LIS variables.
        WRITE(*,*)'NOAH Restart File Used: ',noahdrv%NOAH_RFILE
        READ(40) VCLASS,NC,NR,NCH  !Time, veg class, no. tiles
 write(*,*) VCLASS,NC,NR,NCH
!------------------------------------------------------------------------
!   Check for Vegetation Class Conflict 
!------------------------------------------------------------------------
        IF(VCLASS.NE.LIS%P%VCLASS)THEN
           WRITE(*,*)noahdrv%NOAH_RFILE,LIS%P%VCLASS,VCLASS,' Vegetation class conflict'
           call endrun
        ENDIF
!------------------------------------------------------------------------
!   Check for Grid Space Conflict 
!------------------------------------------------------------------------
        IF(NC.NE.LIS%D%LNC.OR.NR.NE.LIS%D%LNR)THEN
           WRITE(*,*)noahdrv%NOAH_RFILE,'Grid space mismatch - NOAH HALTED'
           call endrun
        ENDIF
!------------------------------------------------------------------------
! Transfer Restart tile space to LIS tile space
!------------------------------------------------------------------------
        IF(NCH.NE.LIS%D%NCH)THEN           
           WRITE(*,*)'Restart Tile Space Mismatch, Halting..'
           call endrun
        endif
        write(*,*) 'start read skin temperature'
        READ(40) noah%tskin         !NOAH Skin Temperature (K)
        write(*,*) 'start read Canopy Water' 
        READ(40) noah%canopy        !NOAH Canopy Water Content (m)
        write(*,*) 'start read snow' 
        READ(40) noah%snwdph      !NOAH Actual Snow Depth (m)
        write(*,*) 'start read SWE'   
        READ(40) noah%weasd      !NOAH Water Equivalent Snow Depth (m) 
        DO L=1,4
           READ(40) TMPTILE !NOAH Soil Layer Temp (4 layers)
           noah%stc(L)=TMPTILE
        ENDDO
        DO L=1,4
           READ(40) TMPTILE !NOAH Total soil moist. (4 layers)
           noah%smc(L)=TMPTILE
        ENDDO
        DO L=1,4
           READ(40) TMPTILE !NOAH Liquid-only soil moist. (4 layers)
           noah%slc(L)=TMPTILE
        ENDDO
        READ(40) noah%chxy         !NOAH Sfc Exchange Coef. for Heat/Moisture
        READ(40) noah%cmxy         !NOAH Sfc Exchange Coef. for Momentum
        READ(40) noah%zorl
        READ(40) noah%tsurf
        READ(40) noah%trans
! NOAHMP intials
        READ(40) noah%tprcp
        READ(40) noah%srflag
        READ(40) noah%alboldxy
        READ(40) noah%sneqvoxy
        READ(40) noah%tahxy
        READ(40) noah%eahxy
        READ(40) noah%fwetxy
        READ(40) noah%canliqxy
        READ(40) noah%canicexy
        READ(40) noah%tvxy
        READ(40) noah%tgxy
        READ(40) noah%qsnowxy
        READ(40) noah%snowxy
        READ(40) noah%zwtxy
        READ(40) noah%waxy
        READ(40) noah%wtxy
        READ(40) noah%wslakexy
        READ(40) noah%lfmassxy
        READ(40) noah%rtmassxy
        READ(40) noah%stmassxy
        READ(40) noah%woodxy
        READ(40) noah%stblcpxy
        READ(40) noah%fastcpxy
        READ(40) noah%xlaixy
        READ(40) noah%xsaixy
        READ(40) noah%taussxy
        READ(40) noah%smcwtdxy
        READ(40) noah%deeprechxy
        READ(40) noah%rechxy         
!  ----------- snow/soil temperature [k] -----------------------------
        DO L=1,3
           READ(40) TMPTILE
           noah%tsnoxy(L)=TMPTILE
        ENDDO
! ------------layer-bottom depth from snow surf to 2m soil [m] ---------
         DO L=1,7
           READ(40) TMPTILE
           noah%zsnsoxy(L)=TMPTILE
        ENDDO
! ---------------snow layer ice [mm] ----------------------------------
        DO L=1,3
           READ(40) TMPTILE
           noah%snicexy(L)=TMPTILE
        ENDDO
! --------------snow layer liquid water [mm] ----------------------------
         DO L=1,3
           READ(40) TMPTILE
           noah%snliqxy(L)=TMPTILE
        ENDDO
! --------------equilibrium soil water  content [m3/m3]------------------
        DO L=1,4
           READ(40) TMPTILE
           noah%smoiseq(L)=TMPTILE
        ENDDO

        close(40)        
        deallocate(tmptile)
     endif
  endif

#if ( defined SPMD )
  if ( ( lis%o%startcode == 1 ) .and. ( npes >  1 ) ) then
     call noah_scatter()
  endif
#endif

! print*, noah(180666)%T1
! print*, noah(180666)%CMC
! print*, noah(180666)%SNOWH
! print*, noah(180666)%SNEQV
! print*, noah(180666)%STC
! print*, noah(180666)%SMC
! print*, noah(180666)%SH2O

 if(masterproc)   print*,'DBG: done noahrst',' (',iam,')'
!EOC
end subroutine noahrst
