       CHARACTER*48 FUNCTION TM_FMT_SNGL_TRIM(val, digits, max_len, str_len)

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
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY 
*  SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
*
* convert the value val to a formatted string, left justified, not exceeding
* max_len in length and with the shortest possible format( unnecerssary zeros
* eliminated )

* programmer - Ansley Manke, from tm_fmt.F
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
*
* 1/13/2012
* Single-precision version of TM_FMT, to be called from PPLUS.
*
* *kms*  v7.5 5/19 Change to a wrapper for calling TM_FMT
*                  Return CHARACTER*48 to simplify life.

* calling arguments:
* val      - REAL*4 value to be converted
* digits   - IF >0 maximum number of significant digits desired
*            ELSE  maximum number of decimal places desired
* max_len  - longest allowable length for string to be returned
* str_len  - (returned) actual length of the string generated

        IMPLICIT NONE

* calling argument declarations:
        INTEGER digits, max_len, str_len
        REAL*4  val

* functions:
        CHARACTER*48 TM_FMT

* internal variable declarations:
        REAL*8 dblval
        CHARACTER*48 outstring

        dblval = DBLE(val)
        outstring = TM_FMT(dblval, digits, max_len, str_len)

* Remove any trailing zero's and decimal point if non-exponential 

	CALL TM_CLEANUP_NUM_STRING (outstring, str_len)
        TM_FMT_SNGL_TRIM = outstring

        RETURN

        END

