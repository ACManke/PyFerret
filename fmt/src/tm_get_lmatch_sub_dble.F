	SUBROUTINE TM_GET_LMATCH_SUB_DBLE (gvn, tst, dup_name, dup_guts)

*  Version of TM_GET_LINE_MATCH_SUB for comparing axes using only double precision

* Searches the list of pre-defined line_name's and returns the number
* associated with a "match" on lname. A match means that the the characters
* of lname are all found plus, optionally, digits. If no match is found
* the value unspecified_int4 is returned.

* dup_name - returned TRUE if there is an identical name match
* dup_guts - returned TRUE if there is a pattern name match AND the guts
*	     are identical

* Include files
#include "tmap_dset.parm"	
	include 'tmap_dims.parm'	! 
#include "gt_lib.parm"
	include 'xtm_grid.cmn_text'	! pre-defined grid common
	external xgt_grid_data

* argument variables
	LOGICAL		dup_name, dup_guts
	INTEGER		gvn, tst

* local variable declarations
	LOGICAL		TM_SAME_LINE_DEF_DBLE
	INTEGER*4	TM_LENSTR1, STR_CASE_BLIND_COMPARE
	INTEGER*4	gvn_len, tst_len, istat, ic
	CHARACTER	lname*128, c*1

* initialize
	dup_name = .FALSE.
	dup_guts = .FALSE.
	lname    = line_name(gvn)
	gvn_len  = TM_LENSTR1(lname)

* screen out obvious rejection criteria
	IF ( tst .EQ. gvn ) GOTO 1000	! don't compare to self
	IF ( line_name(tst)  .EQ. char_init16 ) GOTO 1000
	tst_len = TM_LENSTR1( line_name(tst) )
	IF ( tst_len .LT. gvn_len ) GOTO 1000

* test for base name match
	istat = STR_CASE_BLIND_COMPARE
     .			(line_name(tst)(:gvn_len),lname(:gvn_len))
	IF (istat .NE. str_match) GOTO 1000
	IF (tst_len .EQ. gvn_len) dup_name = .TRUE.

* test that only extra digits were added
	DO 90 ic = gvn_len+1, tst_len
	  c = line_name(tst)(ic:ic)
	  IF (  c .LT. '0' .OR. c .GT. '9' ) GOTO 1000
 90	CONTINUE

* found a name pattern match.  Now check if the guts match, too
	dup_guts = TM_SAME_LINE_DEF_DBLE( gvn, tst )

* not a duplicate definition
 1000	RETURN

	END


