	INTEGER FUNCTION TM_GET_LMATCH_DBLE (gvn_line, dup_name, dup_guts)


*  Version of TM_GET_LINE_MATCHfor comparing axes using only double precision

* Searches the list of pre-defined line_name's and returns the number
* associated with a "match" on lname. A match means that the the characters
* of lname are all found plus, optionally, digits. If no match is found
* the value unspecified_int4 is returned.

* dup_name - returned TRUE if there is an identical name match OR (there
*	     is a pattern name match AND the guts are identical)
* dup_guts - returned TRUE if there is a pattern name match AND the guts
*	     are identica
         

* Include files
#include "tmap_dset.parm"	
	include 'tmap_dims.parm'	
#include "gt_lib.parm"

* argument variables
	LOGICAL		dup_name, dup_guts
	INTEGER		gvn_line

* local variable declarations
	LOGICAL		xact_name
	INTEGER*4	i

* initialize
	dup_name = .FALSE.
	TM_GET_LMATCH_DBLE = unspecified_int4

* Note: the code logic appears to return the *last* dup_guts found, but
*       logic in Ferret ensures that there can be at most one such match 

* check the static axes
	DO 100 i=1,max_lines
	  CALL TM_GET_LMATCH_SUB_DBLE(gvn_line, i, xact_name, dup_guts)
	  IF (dup_guts) TM_GET_LMATCH_DBLE = i
	  IF (xact_name) dup_name = .TRUE.
 100	CONTINUE
 
* check the dynamic grids
	i = 0
 200	CALL TM_NEXT_DYN_LINE( i, *299)
	  CALL TM_GET_LMATCH_SUB_DBLE(gvn_line, i, xact_name, dup_guts)
	  IF (dup_guts) TM_GET_LMATCH_DBLE = i
	  IF (xact_name) dup_name = .TRUE.
	GOTO 200

 299	RETURN
	END
