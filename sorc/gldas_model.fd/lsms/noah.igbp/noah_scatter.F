!-------------------------------------------------------------------------
!     NASA GSFC Land Information Systems LIS 2.3                         !
!-------------------------------------------------------------------------
#include <misc.h>
!BOP
!
! !ROUTINE: noah_scatter.F90
!
! !DESCRIPTION:
!  Distributes noah tiles on to compute nodes
!
! !REVISION HISTORY:
! Apr 2003 ; Sujay Kumar, Initial Code
!
! !INTERFACE:
subroutine noah_scatter()
! !USES:
  use tile_spmdMod
  use noah_varder
  use noahpardef_module
!EOP
  IMPLICIT NONE
  integer :: t
!=== End Variable List ===================================================
  integer ierr
!BOC
#if  (defined SPMD)
!jesse, for wcoss
  if(masterproc) then
  print*,"noah_scatter()"
  call MPI_SCATTERV(noah,di_array,displs, & 
       MPI_NOAH_STRUCT,MPI_IN_PLACE,di_array(iam),MPI_NOAH_STRUCT, & 
       0,MPI_COMM_WORLD,ierr)
  else
  call MPI_SCATTERV(noah,di_array,displs, &
       MPI_NOAH_STRUCT,noah,di_array(iam),MPI_NOAH_STRUCT, &
       0,MPI_COMM_WORLD,ierr)
  endif
#endif
!EOC
end subroutine noah_scatter
