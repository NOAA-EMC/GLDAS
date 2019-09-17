! Subroutine SNOW_INIT grabbed from NOAH-MP-WRF
SUBROUTINE SNOW_INIT ( jts, jtf, its, itf, ims, ime, jms, jme, NSNOW, NSOIL, ZSOIL,  &
     SWE, tgxy, SNODEP, ZSNSOXY, TSNOXY, SNICEXY, SNLIQXY, ISNOWXY)

! ------------------------------------------------------------------------------------------
  IMPLICIT NONE
! ------------------------------------------------------------------------------------------
  INTEGER, INTENT(IN) :: jts,jtf,its,itf,ims,ime, jms,jme,NSNOW,NSOIL
  REAL,    INTENT(IN), DIMENSION(ims:ime, jms:jme) :: SWE
  REAL,    INTENT(IN), DIMENSION(ims:ime, jms:jme) :: SNODEP
  REAL,    INTENT(IN), DIMENSION(ims:ime, jms:jme) :: tgxy
  REAL,    INTENT(IN), DIMENSION(1:NSOIL) :: ZSOIL

  INTEGER, INTENT(OUT), DIMENSION(ims:ime, jms:jme) :: ISNOWXY
  REAL,    INTENT(OUT), DIMENSION(ims:ime, -NSNOW+1:NSOIL,jms:jme) :: ZSNSOXY
  REAL,    INTENT(OUT), DIMENSION(ims:ime, -NSNOW+1:    0,jms:jme) :: TSNOXY
  REAL,    INTENT(OUT), DIMENSION(ims:ime, -NSNOW+1:    0,jms:jme) :: SNICEXY
  REAL,    INTENT(OUT), DIMENSION(ims:ime, -NSNOW+1:    0,jms:jme) :: SNLIQXY

!local
  INTEGER :: I,J,IZ
  REAL,                 DIMENSION(ims:ime, -NSNOW+1:    0,jms:jme) :: DZSNOXY
  REAL,                 DIMENSION(ims:ime, -NSNOW+1:NSOIL,jms:jme) :: DZSNSOXY
! ------------------------------------------------------------------------------
   DO J = jts,jtf
     DO I = its,itf
        IF (SNODEP(I,J) < 0.025) THEN
           ISNOWXY(I,J) = 0
           DZSNOXY(I,-NSNOW+1:0,J) = 0.
        ELSE
           IF ((SNODEP(I,J) >= 0.025) .AND. (SNODEP(I,J) <= 0.05)) THEN
              ISNOWXY(I,J)    = -1
              DZSNOXY(I,0,J)  = SNODEP(I,J)
           ELSE IF ((SNODEP(I,J) > 0.05) .AND. (SNODEP(I,J) <= 0.10)) THEN
              ISNOWXY(I,J)    = -2
              DZSNOXY(I,-1,J) = SNODEP(I,J)/2.
              DZSNOXY(I, 0,J) = SNODEP(I,J)/2.
           ELSE IF ((SNODEP(I,J) > 0.10) .AND. (SNODEP(I,J) <= 0.25)) THEN
              ISNOWXY(I,J)    = -2
              DZSNOXY(I,-1,J) = 0.05
              DZSNOXY(I, 0,J) = SNODEP(I,J) - DZSNOXY(I,-1,J)
           ELSE IF ((SNODEP(I,J) > 0.25) .AND. (SNODEP(I,J) <= 0.35)) THEN
              ISNOWXY(I,J)    = -3
              DZSNOXY(I,-2,J) = 0.05
              DZSNOXY(I,-1,J) = 0.5*(SNODEP(I,J)-DZSNOXY(I,-2,J))
              DZSNOXY(I, 0,J) = 0.5*(SNODEP(I,J)-DZSNOXY(I,-2,J))
           ELSE IF (SNODEP(I,J) > 0.35) THEN
              ISNOWXY(I,J)     = -3
              DZSNOXY(I,-2,J) = 0.05
              DZSNOXY(I,-1,J) = 0.10
              DZSNOXY(I, 0,J) = SNODEP(I,J) - DZSNOXY(I,-1,J) - DZSNOXY(I,-2,J)
           END IF
        END IF
     ENDDO
  ENDDO

  DO J = jts,jtf
     DO I = its,itf
        TSNOXY( I,-NSNOW+1:0,J) = 0.
        SNICEXY(I,-NSNOW+1:0,J) = 0.
        SNLIQXY(I,-NSNOW+1:0,J) = 0.
        DO IZ = ISNOWXY(I,J)+1, 0
           TSNOXY(I,IZ,J)  = tgxy(I,J)  ! [k]
           SNLIQXY(I,IZ,J) = 0.00
           SNICEXY(I,IZ,J) = 1.00 * DZSNOXY(I,IZ,J) * (SWE(I,J)/SNODEP(I,J))  ! [kg/m3]
        END DO

         DO IZ = ISNOWXY(I,J)+1, 0
           DZSNSOXY(I,IZ,J) = -DZSNOXY(I,IZ,J)
        END DO

        DZSNSOXY(I,1,J) = ZSOIL(1)
        DO IZ = 2,NSOIL
           DZSNSOXY(I,IZ,J) = (ZSOIL(IZ) - ZSOIL(IZ-1))
        END DO

        ZSNSOXY(I,ISNOWXY(I,J)+1,J) = DZSNSOXY(I,ISNOWXY(I,J)+1,J)
        DO IZ = ISNOWXY(I,J)+2 ,NSOIL
           ZSNSOXY(I,IZ,J) = ZSNSOXY(I,IZ-1,J) + DZSNSOXY(I,IZ,J)
        ENDDO

     END DO
  END DO

END SUBROUTINE SNOW_INIT

