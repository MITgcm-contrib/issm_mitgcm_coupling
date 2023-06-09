#include "SHELFICE_OPTIONS.h"

CBOP
      SUBROUTINE SHELFICE_INIT_VARIA( myThid )
C     *============================================================*
C     | SUBROUTINE SHELFICE_INIT_VARIA
C     | o Routine to initialize SHELFICE variables.
C     *============================================================*
C     | Initialize SHELFICE parameters and variables.
C     *============================================================*
      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "SHELFICE.h"
#ifdef ALLOW_COST
# include "SHELFICE_COST.h"
#endif /* ALLOW_COST */

C     === Routine arguments ===
C     myThid -  Number of this instance of SHELFICE_INIT_VARIA
      INTEGER myThid
CEndOfInterface

#ifdef ALLOW_SHELFICE
C     === Local variables ===
C     i,j,bi,bj - Loop counters
      INTEGER i, j, bi, bj
CEOP

      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        DO j = 1-OLy, sNy+OLy
         DO i = 1-OLx, sNx+OLx
          shelficeForcingT      (i,j,bi,bj) = 0. _d 0
          shelficeForcingS      (i,j,bi,bj) = 0. _d 0
          shelficeHeatFlux      (i,j,bi,bj) = 0. _d 0
          shelficeFreshWaterFlux(i,j,bi,bj) = 0. _d 0
          shiTransCoeffT        (i,j,bi,bj) = 0. _d 0
          shiTransCoeffS        (i,j,bi,bj) = 0. _d 0
          shelficeSubglFlux     (i,j,bi,bj) = 0. _d 0
          IF ( .NOT. useCoupler ) shelficeMass (i,j,bi,bj) = 0. _d 0
          shelficeSubglFlux0    (i,j,bi,bj) = 0. _d 0
          shelficeSubglFlux1    (i,j,bi,bj) = 0. _d 0
          shiCdrag_fld          (i,j,bi,bj) = 0. _d 0
         ENDDO
        ENDDO
       ENDDO
      ENDDO
      IF ( .NOT. SHELFICEuseGammaFrict ) THEN
       IF ( SHELFICETransCoeffTFile .NE. ' ' ) THEN
        CALL READ_FLD_XY_RL( SHELFICETransCoeffTFile, ' ',
     &                       shiTransCoeffT, 0, myThid )
        _EXCH_XY_RL( shiTransCoeffT, myThid )
        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
          DO j = 1-OLy, sNy+OLy
           DO i = 1-OLx, sNx+OLx
            shiTransCoeffS(i,j,bi,bj) = 5.05 _d -3 *
     &                                  shiTransCoeffT(i,j,bi,bj)
           ENDDO
          ENDDO
         ENDDO
        ENDDO
       ELSE
C     set coefficients to constant values
        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
          DO j = 1-OLy, sNy+OLy
           DO i = 1-OLx, sNx+OLx
            shiTransCoeffT(i,j,bi,bj) = SHELFICEheatTransCoeff
            shiTransCoeffS(i,j,bi,bj) = SHELFICEsaltTransCoeff
           ENDDO
          ENDDO
         ENDDO
        ENDDO
       ENDIF
      ENDIF

      IF ( .NOT. useCoupler ) THEN
       DO bj = myByLo(myThid), myByHi(myThid)
        DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j = 1-OLy, sNy+OLy
          DO i = 1-OLx, sNx+OLx
           shelficeMass(i,j,bi,bj) = shelficeMassInit(i,j,bi,bj)
          ENDDO
         ENDDO
        ENDDO
       ENDDO
      ENDIF

      IF ( SHELFICEMassStepping .AND.
     &     ( nIter0.NE.0 .OR. startTime.NE.baseTime
     &                   .OR. pickupSuff.NE.' ') ) THEN
        CALL SHELFICE_READ_PICKUP( 1, nIter0, myThid )
      ENDIF

      IF ( SHELFICEaddrunoff .AND.
     &     SHELFICESubglFluxFile .NE. ' ' ) THEN
       CALL READ_FLD_XY_RS( SHELFICESubglFluxFile, ' ',
     &                      shelficeSubglFlux, 0, myThid )
       _EXCH_XY_RL( shelficeSubglFlux, myThid )
      ENDIF

      IF ( SHELFICECdragFile .NE. ' ') then
       CALL READ_FLD_XY_RS( SHELFICECdragFile, ' ',
     &                      shiCdrag_fld, 0, myThid )
      ELSE
       DO bj = myByLo(myThid), myByHi(myThid)
        DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j = 1-OLy, sNy+OLy
          DO i = 1-OLx, sNx+OLx
           shiCdrag_fld (i,j,bi,bj) = shiCdrag
          ENDDO
         ENDDO
        ENDDO
       ENDDO
      ENDIF




#ifdef ALLOW_COST
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j = 1-OLy, sNy+OLy
          DO i = 1-OLx, sNx+OLx
           cMeanSHIforT (i,j,bi,bj) = 0. _d 0
           cMeanSHIforS (i,j,bi,bj) = 0. _d 0
          ENDDO
         ENDDO
       ENDDO
      ENDDO
c--
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        objf_shelfice(bi,bj) = 0. _d 0
        objf_shifwflx(bi,bj) = 0. _d 0
        num_shifwflx(bi,bj)  = 0. _d 0
       ENDDO
      ENDDO
#endif /* ALLOW_COST */

#endif /* ALLOW_SHELFICE */

      RETURN
      END
