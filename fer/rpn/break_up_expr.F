	SUBROUTINE BREAK_UP_EXPR( text, num_parts, status )

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without any fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and any derivative works thereof, and
*  its supporting documentation for any purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in any publications that result from
*  the use of this software or in any product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in any advertising or publicity to endorse or promote any products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with any support, consulting,
*  training or assistance of any kind with regard to the use, operation
*  and performance of this software nor to provide the user with any
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND ANY EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
*
* text may have more than one algebraic expression separated by commas
* this routine will delimit the expressions and store them in reverse Polish
* order in the user-var structure

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* revision 0.0 - 2/23/87
* V200:  6/20/89 - pass "implct_defn" to initialize user vars from here
*       11/27/89 - perform Reverse Polish translation
*        2/29 90 - don't double-report INIT_UVAR errors
* Unix/RISC port - 1/91 - cant use "//" with CHAR*(*) variable
*       10/22/92 - added units on uvars
* V402:  7/95 - Added "dset" argument to INIT_UVAR for  LET/D=dset var = ... 
* V450:  11/96 - Using reformulated version of INIT_UVAR (RPN called
*		 from there). Part of changes to support external function.
* V510: 5/00 *sh* - added "bad" (missing value flag) to INIT_UVAR arguments
* V540:12/01 *acm*- for parsing expr like def axis/x x1={ 1, 2 } dont include
*                   the brackets in risc_buff
* 1/03 *kob* g77 port - requires use of risc_buff for concats
* V611 5/08 *acm* Fix bug 1578; dataset specifiers applied correctly var[d=1].attname
* V62   2/09 *acm* init_uvar has an extra argument, for keeping upper/lowrercase 
*                  spelling of user-var names (no other changes in this routine).
*       *acm* 3/12 6D Ferret (common uses nferdims in tmap_dims.parm)
* V685+ 12/13    - *acm*  bounds checking; dont refer to parts of the string outside its bounds.
* V710 9/16  *acm* ticket 2465: Parsing expressions including attribute references.

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include	'ferret.parm'
	include 'errmsg.parm'	
	include 'rpn.parm'
	include 'xprog_state.cmn'
	include 'xrisc.cmn'

* calling argument declaration:
	INTEGER		num_parts, status
	CHARACTER*(*)	text

* internal parameter declarations:
	LOGICAL		implct_defn
	PARAMETER     ( implct_defn = .TRUE. )

* internal variable declarations:
	LOGICAL its_remote
	INTEGER	TM_LENSTR1,
     .		tlen, uvar, natom, i, paren_level, at1,
     .		at_type  (maxatoms), at_id  (maxatoms),
     .		at_start (maxatoms), at_end (maxatoms),
     .		exp_start(max_exp), exp_end(max_exp),
     .		atom_1   (max_exp), atom_n (max_exp),
     .          paren, startparen
	CHARACTER	EXPR_NAME*8, err_string*128, t2*2

        INTEGER ii

* initialize fixed length string for RISC
* If curly-brackets, dont count them.

        risc_buff = text
c        tlen = MIN( size_rbuff, LEN(text) )

        IF (text(1:1) .EQ. '{') THEN
            DO ii = 2, LEN(risc_buff)
               risc_buff(ii:ii) = text(ii:ii)
               IF (text(ii:ii) .EQ. '}') THEN
                  go to 499 
               ENDIF
             ENDDO
  499        CONTINUE
        ENDIF
        tlen = MIN( size_rbuff, LEN(text) )

* break the expression into atoms

* ----
* When there is a .. in the expression, this will later be translated
* as an attribute of the dataset.  Here just gloss over this by
* temporarily replacing the two dots with a string.

	IF (LEN(text) .GT. 1 .AND. INDEX(text,'..') .GT. 0) THEN
           DO ii = 1, TM_LENSTR1(risc_buff)-1
              IF (text(ii:ii+1) .EQ. '..') text(ii:ii+1) = 'aa'
	   ENDDO
	ENDIF

* a similar hack when the expression is (coordvar).attname 
* ALG_BREAK_UP can parse this, but doesnt like more complicated expressions
* like (coordvar).attname[d=2] Could make more cases in alg_break_up, but
* instead avoid the confusion about the meaning of the parentheses by 
* temporarily removing them.

        paren = 0
        IF ( INDEX(text, ').' )  .NE. 0) THEN
           paren = INDEX(text, ').' )
           DO 80 i = paren-1,1,-1
              startparen = INDEX(text(i:paren), '(' )
   80      CONTINUE
           IF (startparen .EQ. 0) GOTO 5400
           text(startparen:startparen) = 'A'
           TEXT(paren:paren) = 'A'
        ENDIF

* a similar hack when the expression is (coordvar)[spec].attname 
* ALG_BREAK_UP can parse this, but doesnt like more complicated expressions
* like (coordvar).attname[d=2] Could make more cases in alg_break_up, but
* instead avoid the confusion about the meaning of the parentheses by 
* temporarily removing them.

        IF ( INDEX(text, ')[' )  .NE. 0 .AND. 
     .       INDEX(text, '].' )  .NE. 0) THEN
           paren = INDEX(text, ')[' )
           DO 90 i = paren-1,1,-1
              startparen = INDEX(text(i:paren), '(' )
   90      CONTINUE
           IF (startparen .EQ. 0) GOTO 5400
           text(startparen:startparen) = 'A'
           TEXT(paren:paren) = 'A'
        ENDIF

	CALL ALG_BREAK_UP( text,at_start,at_end,natom,err_string,status )

* ----
* Restore text before the hack

	text = risc_buff

	IF ( status .NE. ferr_ok ) GOTO 5100

* identify the atoms
	CALL ALG_ID( text, natom, at_start, at_end, at_type, at_id, status )
	IF ( status .NE. ferr_ok ) GOTO 5000

* locate the sub-expressions by looking for commas that are outside of
* enclosing parentheses
	num_parts    = 1
	exp_start(1) = 1
	atom_1(1)    = 1
	paren_level  = 0
	DO 100 i = 1, natom
	   IF ( at_type(i) .EQ. alg_punctuation ) THEN
	      IF ( at_id(i) .EQ. left_paren ) THEN
	         paren_level = paren_level + 1
	      ELSEIF (at_id(i) .EQ. right_paren ) THEN
	         paren_level = paren_level - 1
	      ELSEIF  (at_id(i) .EQ. comma ) THEN
	         IF ( paren_level .EQ. 0 ) THEN
	            IF ( i.EQ.1 .OR.  i.EQ.natom ) GOTO 5200
	            IF ( num_parts .GE. max_exp  ) GOTO 5300
	            IF ( at_type(i+1) .EQ. alg_punctuation
     .		   .AND. at_id(i+1)   .EQ. comma ) GOTO 5200
	            atom_n (num_parts) = i - 1
	            exp_end(num_parts) = at_end(i-1)
	            num_parts = num_parts + 1
	            exp_start(num_parts) = at_start(i+1)
	            atom_1(num_parts) = i + 1
	         ENDIF
	      ENDIF
	   ENDIF
 100	CONTINUE
	atom_n (num_parts) = natom
	exp_end(num_parts) = at_end(natom)

* now file the expression in the user-defined variable area
        its_remote = .FALSE.  ! LET/REMOTE only with LET itself.

	DO 200 i = 1, num_parts
	   at1 = atom_1(i)
	   CALL INIT_UVAR( EXPR_NAME(i),text,' ', ' ', unspecified_int4,
     .			   bad_val4, implct_defn, uvar,
     .			   at_type(at1),  at_id(at1),
     .			   at_start(at1), at_end(at1),
     .			   atom_n(i)-at1+1,
     .			   exp_start(i), exp_end(i), 
     .			   EXPR_NAME(i), its_remote, status )
	   IF ( status .NE. ferr_ok ) GOTO 5000
 200	CONTINUE

* successful completion
 1000	status = ferr_ok
	RETURN

* error exits
 5000	num_parts = cmnd_uvars_not_given
	RETURN
 5100	CALL ERRMSG( status, status,
     .			risc_buff(:tlen)//pCR//err_string, *5000 )
 5200	risc_buff = text(:tlen)
	CALL ERRMSG( ferr_syntax, status,
     .		'comma does not separate any expressions: '
     .			//risc_buff, *5000 )
 5300   write ( err_string, '(I4)' ) max_exp
	CALL ERRMSG( ferr_invalid_command, status,
     .		'Number of expressions in line must be less than'
     .		//err_string(:4), *5000 )
 5400   CALL ERRMSG( ferr_invalid_command, status,
     .		'Mismatched parentheses'
     .		//text(1:paren), *5000 )
	END

