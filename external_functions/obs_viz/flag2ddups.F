	SUBROUTINE FLAG2DDUPS( n, x, y, epsx, epsy, dup, seq )

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

* Locate the duplicate coordinate pairs in a list of coordinates
* Will be regarded as duplicate if X lies within espx distance and ditto y
* The array "dup" will contain the number of duplicate "mates" for any
*   given coordinate (i.e. 0 if no matches)
* The array "seq' will contain the sequence number 0,1,2,... of the mates 

* V530 *sh* 2/01

* Argument declarations
	INTEGER	n
	REAL	epsx, epsy, x(n), y(n), dup(n), seq(n)

* Internal variable declarations
        INTEGER ii, jj, ndup
        REAL xtarget, ytarget

* initialize
        DO ii = 1, n
          dup(ii) = 0
          seq(ii) = 0
        END DO

* find and label duplicates
        DO ii = 1, n
           
* locate a unique coordinate
           IF (dup(ii) .EQ. 0 ) THEN
             xtarget = x(ii)
             ytarget = y(ii)

* mark sequence numbers for duplicates of this target
             ndup = 0
             DO jj = ii+1, n
               IF (dup(jj) .EQ. 0 ) THEN
                  IF ( (ABS(xtarget-x(jj)) .LE. epsx)
     .           .AND. (ABS(ytarget-y(jj)) .LE. epsy) ) THEN
                    ndup = ndup + 1
                    seq(jj) = ndup
                  ENDIF
               ENDIF
             END DO

* mark number of duplicates found on each member of duplicate group
             dup(ii) = ndup
             IF (ndup .GT. 0) THEN
               DO jj = ii+1, n
                 IF ( (dup(jj).EQ.0)
     .          .AND. (seq(jj).GT.0) ) dup(jj) = ndup 
               END DO
             ENDIF

           ENDIF
        END DO

	RETURN
	END
