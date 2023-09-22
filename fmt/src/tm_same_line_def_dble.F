	LOGICAL FUNCTION TM_SAME_LINE_DEF_DBLE ( line1, line2 )

*  Version of TM_SAME_LINE_DEF for comparing axes using only double precision


* Include files
	include 'tmap_dims.parm'
	include 'implicit.parm'
#include "tmap_dset.parm"
#include "gt_lib.parm"
	include 'xtm_grid.cmn_text'
	external xgt_grid_data

* Argument definitions
	INTEGER*4	line1, line2

* Local definitions
        LOGICAL         TM_FPEQ, TM_DFPEQ, dynamic
	INTEGER*4	TM_LENSTR1, STR_CASE_BLIND_COMPARE, len, istat, j
	REAL*8		TM_WORLD_AX, xx1, xx2
	REAL*8  adouble, bdouble

* local parameter declaration
* ... all these are somewhat arbitrary
	REAL*8	    haf_dp_eps, max_sp_compare
	PARAMETER ( max_sp_compare = 2.**24,
     .              haf_dp_eps = 10.D0**(-14) ) ! somewhat arbitrary

* Same regularity/irregularity?
	  IF (line_regular(line1) .NEQV. line_regular(line2)) GOTO 1000

* Same modulo?
	  IF (line_modulo(line1) .NEQV. line_modulo(line2)) GOTO 1000

* Same modulo length?
	  IF (line_modulo(line1)) THEN
	     IF (line_modulo_len(line1) .NE. line_modulo_len(line2))
     .								GOTO 1000
	  ENDIF

* Check length
	  IF (line_dim(line1) .NE. line_dim(line2)) GOTO 1000

* Check units (2/95 - either a recognized unit code or identical strings)
	  IF (line_unit_code(line1) .NE. line_unit_code(line2)) GOTO 1000
	  IF (line_unit_code(line1) .EQ. 0 ) THEN
	     IF (line_units(line1) .NE. line_units(line2)) GOTO 1000
	  ENDIF
* Check orientation
	  IF (line_direction(line1) .NE. line_direction(line2)) GOTO 1000

* DSG axes are unique per dataset
	  IF (line_dsg_dset(line1) .NE. line_dsg_dset(line2) .AND. 
     .          line_dsg_dset(line1).NE.line_0 .AND. line_dsg_dset(line2).NE.line_0)   GOTO 1000

* Check special values for time axis
	  IF (line_direction(line2) .EQ. 'TI') THEN

	    len = TM_LENSTR1( line_t0(line1) )
	    istat = STR_CASE_BLIND_COMPARE(line_t0(line2)(:len),line_t0(line1)(:len))
	    IF (istat .NE. str_match) GOTO 1000
c	    IF (line_t0(line2) .NE. line_t0(line1)) GOTO 1000

	    IF (line_shift_origin(line2) .NEQV. line_shift_origin(line1))
     .           GOTO 1000
	    IF (line_tunit(line2) .NE. line_tunit(line1)) GOTO 1000
	    IF (line_cal_name(line1) .NE. line_cal_name(line2)) GOTO 1000
	  ENDIF

* dynamic line info
	  dynamic = line1.GT.max_lines .OR. line2.GT.max_lines
	  IF ( line_class (line1) .NE. line_class (line2) ) GOTO 1000
	  IF ( line_parent(line1) .NE. line_parent(line2) ) GOTO 1000

* check coordinate and box locations
	  IF ( line_regular(line2)
     .	.OR.   (line_class (line1) .EQ. pline_class_stride)
     .	.OR.   (line_class (line1) .EQ. pline_class_midpt)   ) THEN
	    adouble = line_start(line1)
	    bdouble = line_start(line2)
            IF ( .NOT. TM_FPEQ( adouble, bdouble ) ) GOTO 1000
	    adouble = line_delta(line1)
	    bdouble = line_delta(line2)
            IF ( .NOT. TM_FPEQ( adouble, bdouble ) ) GOTO 1000
	  ELSE
* irregular lines
	    DO 100 j = 1,line_dim(line1)
* first check the grid points
	      xx1 = TM_WORLD_AX(j, line1, box_middle)
	      xx2 = TM_WORLD_AX(j, line2, box_middle)
	      
	      IF (.NOT. TM_DFPEQ(ABS(xx1), 0.D0) ) THEN
	         IF ( TM_DFPEQ(ABS(xx1), -1*ABS(xx2)) ) GOTO 1000
              ENDIF
              
* ... full precision comparison 
              IF ( xx1 .EQ. xx2 ) GOTO 100
* ... they're not equal but they may be within machine accuracy
              IF ( ABS((xx2-xx1)/(xx2+xx1)) .GT. haf_dp_eps )
     .							    GOTO 1000

* now the grid cell bounds
	      xx1 = TM_WORLD_AX(j, line1, box_lo_lim)
	      xx2 = TM_WORLD_AX(j, line2, box_lo_lim)
	      IF (.NOT. TM_DFPEQ(ABS(xx1), 0.D0) )  THEN
	         IF ( TM_DFPEQ(ABS(xx1), -1*ABS(xx2)) ) GOTO 1000
              ENDIF
* ... full precision comparison
              IF ( xx1 .EQ. xx2 ) GOTO 100
* ... they're not equal but they may be within machine accuracy
              IF ( ABS((xx2-xx1)/(xx2+xx1)) .GT. haf_dp_eps )
     .							    GOTO 1000

  100	    CONTINUE

* finally the upper limit of the top cell
	    xx1 = TM_WORLD_AX(j, line1, box_hi_lim)
	    xx2 = TM_WORLD_AX(j, line2, box_hi_lim)
	    IF (.NOT. TM_DFPEQ(ABS(xx1), 0.D0) )  THEN
	         IF ( TM_DFPEQ(ABS(xx1), -1*ABS(xx2)) ) GOTO 1000
	    ENDIF
            
* ... full precision comparison 
	    IF ( xx1 .EQ. xx2 ) GOTO 500
* ... they're not equal but they may be within machine accuracy
	    IF ( ABS((xx2-xx1)/(xx2+xx1)) .GT. haf_dp_eps )
     .							    GOTO 1000

	  ENDIF

* the lines are identical
 500	  TM_SAME_LINE_DEF_DBLE = .TRUE.
        RETURN

* the lines differ
 1000   TM_SAME_LINE_DEF_DBLE = .FALSE.

        RETURN
	END

