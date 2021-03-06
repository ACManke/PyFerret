*
* sampleyz.F
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without anx fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and anx derivative works thereof, and
*  its supporting documentation for anx purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in anx publications that result from
*  the use of this software or in anx product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in anx advertising or publicity to endorse or promote anx products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with anx support, consulting,
*  training or assistance of anx kind with regard to the use, operation
*  and performance of this software nor to provide the user with anx
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND Anx EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR Anx SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR Anx DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
* Ansley Manke
* From samplexy.F
* Wednesday, May 02, 2001
* 11-Jan-06 *acm* declare ylo, yhi, zlo, zhi as integer not real
*
* This function samples 4-d data at y and z pts indicated by args 2 and 3
* 
*         Result is abstract on the Y axis, normal on the z axis,
*         and keeps the x and t axes of the input 4-d data.

* In this subroutine we provide information about
* the function.  The user configurable information 
* consists of the following:
*
* descr              Text description of the function
*
* num_args           Required number of arguments
*
* axis_inheritance   Type of axis for the result
*                       ( CUSTOM, IMPLIED_BY_ARGS, NORMAL, ABSTRACT )
*                       CUSTOM          - user defined axis
*                       IMPLIED_BY_ARGS - same axis as the incoming argument
*                       NORMAL          - the result is normal to this axis
*                       ABSTRACT        - an axis which only has index values
*
* piecemeal_ok       For memory optimization:
*                       axes where calculation may be performed piecemeal
*                       ( YES, NO )
* 
*
* For each argument we provide the following information:
*
* name               Text name for an argument
*
* unit               Text units for an argument
*
* desc               Text description of an argument
*
* axis_influence     Are this argument's axes the same as the result grid?
*                       ( YES, NO )
*
* axis_extend       How much does Ferret need to extend arg limits relative to result 
*


      SUBROUTINE sampleyz_init(id)

      INCLUDE 'ferret_cmn/EF_Util.cmn'

      INTEGER id, arg

***********************************************************************
*                                           USER CONFIGURABLE PORTION |
*                                                                     |
*                                                                     V
      CHARACTER*100 fcn_desc
      WRITE (fcn_desc, 10)
   10 FORMAT ('Returns data sampled at a set of (Y,X) points, ',
     .   'using linear interpolation')
      CALL ef_set_desc(id, fcn_desc)

      CALL ef_set_num_args(id, 3)
      CALL ef_set_has_vari_args(id, NO)
      CALL ef_set_axis_inheritance(id, IMPLIED_BY_ARGS, ABSTRACT, 
     .     NORMAL, IMPLIED_BY_ARGS)

      CALL ef_set_piecemeal_ok(id, NO, NO, NO, NO)

      CALL ef_set_num_work_arrays(id, 2)

      arg = 1
      CALL ef_set_arg_name(id, arg, 'DAT_TO_SAMPLE')
      CALL ef_set_arg_desc(id, arg, 'variable (x,y,z,t) to sample')
      CALL ef_set_axis_influence(id, arg, YES, NO, NO, YES)

      arg = 2
      CALL ef_set_arg_name(id, arg, 'YPTS')
      CALL ef_set_arg_desc(id, arg, 'Y values of sample points')
      CALL ef_set_axis_influence(id, arg, NO, NO, NO, NO)

      arg = 3
      CALL ef_set_arg_name(id, arg, 'ZPTS')
      CALL ef_set_arg_desc(id, arg, 'Z values of sample points')
      CALL ef_set_axis_influence(id, arg, NO, NO, NO, NO)
*                                                                     ^
*                                                                     |
*                                           USER CONFIGURABLE PORTION |
***********************************************************************

      RETURN 
      END

*
* In this subroutine we provide information about the lo and hi
* limits associated with each abstract or custom axis.   The user 
* configurable information consists of the following:
*
* loss               lo subscript for an axis
*
* hiss               hi subscript for an axis
*

      SUBROUTINE sampleyz_result_limits(id)

      INCLUDE 'ferret_cmn/EF_Util.cmn'

      INTEGER id
      INTEGER arg_lo_ss(4,EF_MAX_ARGS), arg_hi_ss(4,EF_MAX_ARGS),
     .     arg_incr(4,EF_MAX_ARGS)

* **********************************************************************
*                                           USER CONFIGURABLE PORTION |
*                                                                     |
*                                                                     V

      INTEGER mz_lo_l, mz_hi_l
      INTEGER nx, ny, nz, nt

*     Use utility functions to get context information about the 
*     1st argument, to set the abstract axis lo and hi indices.

      CALL ef_get_arg_subscripts(id, arg_lo_ss, arg_hi_ss, arg_incr)

      nx = arg_hi_ss(X_AXIS, ARG2) - arg_lo_ss(X_AXIS, ARG2) + 1
      ny = arg_hi_ss(Y_AXIS, ARG2) - arg_lo_ss(Y_AXIS, ARG2) + 1
      nz = arg_hi_ss(Z_AXIS, ARG2) - arg_lo_ss(Z_AXIS, ARG2) + 1
      nt = arg_hi_ss(T_AXIS, ARG2) - arg_lo_ss(T_AXIS, ARG2) + 1

      mz_lo_l = 1
      mz_hi_l = max(nx,ny)
      mz_hi_l = max(mz_hi_l,nz)
      mz_hi_l = max(mz_hi_l,nt)

      CALL ef_set_axis_limits(id, Y_AXIS, mz_lo_l, mz_hi_l)

*                                                                     ^
*                                                                     |
*                                           USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END
*
* In this subroutine we request an amount of storage to be supplied
* by Ferret and passed as an additional argument.
*
      SUBROUTINE sampleyz_work_size(id)

      INCLUDE 'ferret_cmn/EF_Util.cmn'
      INCLUDE 'ferret_cmn/EF_mem_subsc.cmn'

      INTEGER id

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

*
* Set the work arrays,  X/Y/Z/T dimensions
*
* ef_set_work_array_lens(id,array #,ylo,zlo,zlo,tlo,yhi,zhi,zhi,thi)
*
      INTEGER myl, myh, mzl, mzh

      INTEGER arg_lo_ss(4,1:EF_MAX_ARGS), arg_hi_ss(4,1:EF_MAX_ARGS),
     .     arg_incr(4,1:EF_MAX_ARGS)

      CALL ef_get_arg_subscripts(id, arg_lo_ss, arg_hi_ss, arg_incr)

*  Allocate double the length of the axes for REAL*8 work arrays.

      myl = arg_lo_ss(Y_AXIS,ARG1)
      mzl = arg_lo_ss(Z_AXIS,ARG1)

      myh = myl + 
     .     2* (arg_hi_ss(Y_AXIS,ARG1) - arg_lo_ss(Y_AXIS,ARG1) + 1)
      mzh = mzl + 
     .     2* (arg_hi_ss(Z_AXIS,ARG1) - arg_lo_ss(Z_AXIS,ARG1) + 1)

*  yax
      CALL ef_set_work_array_dims (id, 1, myl, 1, 1, 1, myh, 1, 1, 1)

*  zax
      CALL ef_set_work_array_dims (id, 2, mzl, 1, 1, 1, mzh, 1, 1, 1)


*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END

*
* In this subroutine we compute the result
*

      SUBROUTINE sampleyz_compute(id, arg_1, arg_2, arg_3, result,
     .       yax, zax)

      INCLUDE 'ferret_cmn/EF_Util.cmn'
      INCLUDE 'ferret_cmn/EF_mem_subsc.cmn'

      INTEGER id

      REAL bad_flag(EF_MAX_ARGS), bad_flag_result
      REAL arg_1(mem1lox:mem1hix, mem1loy:mem1hiy, mem1loz:mem1hiz,
     .     mem1lot:mem1hit)
      REAL arg_2(mem2lox:mem2hix, mem2loy:mem2hiy, mem2loz:mem2hiz,
     .     mem2lot:mem2hit)
      REAL arg_3(mem3lox:mem3hix, mem3loy:mem3hiy, mem3loz:mem3hiz,
     .     mem3lot:mem3hit)
      REAL result(memreslox:memreshix, memresloy:memreshiy,
     .      memresloz:memreshiz, memreslot:memreshit)


* After initialization, the 'res_' arrays contain indexing information
* for the result axes.  The 'arg_' arrays will contain the indexing
* information for each variable's axes.

      INTEGER res_lo_ss(4), res_hi_ss(4), res_incr(4)
      INTEGER arg_lo_ss(4,EF_MAX_ARGS), arg_hi_ss(4,EF_MAX_ARGS),
     .     arg_incr(4,EF_MAX_ARGS)

***********************************************************************
*                                           USER CONFIGURABLE PORTION |
*                                                                     |
*                                                                     V
      COMMON /STOR/ mydat, mzdat
      INTEGER mydat, mzdat
      INTEGER ny, nyx, nyy, nyz, nyt
      INTEGER nz, nzx, nzy, nzz, nzt
      INTEGER ndimy, ndimz

*  Set up work arrays

      REAL*8 yax(wrk1lox:wrk1lox+(wrk1hix-wrk1lox)/2,wrk1loy:wrk1hiy,
     .               wrk1loz:wrk1hiz, wrk1lot:wrk1hit)
      REAL*8 zax(wrk2lox:wrk2lox+(wrk2hix-wrk2lox)/2,wrk2loy:wrk2hiy,
     .               wrk2loz:wrk2hiz, wrk2lot:wrk2hit)

      INTEGER i, j, k, l
      INTEGER i1,j1,k1,l1
      INTEGER i2,j2,k2,l2
      INTEGER i3,j3,k3,l3

      INTEGER jmatch, kmatch
      INTEGER jbot, jtop, kbot, ktop
      REAL fbot, ftop, fbb, ftb, fbt, ftt
      REAL ybot, ytop, zbot, ztop
      REAL frac
      CHARACTER*255 err_msg

C  variables for checking axis characteristics (modulo axes)

      CHARACTER ax_name(4)*16, ax_units(4)*16
      LOGICAL backward(4), modulo(4), regular(4)
      REAL delmody, delmodz, ypt, zpt
      INTEGER ylo, yhi, zlo, zhi

      CALL ef_get_res_subscripts(id, res_lo_ss, res_hi_ss, res_incr)
      CALL ef_get_arg_subscripts(id, arg_lo_ss, arg_hi_ss, arg_incr)
      CALL ef_get_bad_flags(id, bad_flag, bad_flag_result)

      nyx = arg_hi_ss(X_AXIS,ARG2) - arg_lo_ss(X_AXIS,ARG2) + 1
      nyy = arg_hi_ss(Y_AXIS,ARG2) - arg_lo_ss(Y_AXIS,ARG2) + 1
      nyz = arg_hi_ss(Z_AXIS,ARG2) - arg_lo_ss(Z_AXIS,ARG2) + 1
      nyt = arg_hi_ss(T_AXIS,ARG2) - arg_lo_ss(T_AXIS,ARG2) + 1
      ny = max(nyx, nyy, nyz, nyt)

      nzx = arg_hi_ss(X_AXIS,ARG3) - arg_lo_ss(X_AXIS,ARG3) + 1
      nzy = arg_hi_ss(Y_AXIS,ARG3) - arg_lo_ss(Y_AXIS,ARG3) + 1
      nzz = arg_hi_ss(Z_AXIS,ARG3) - arg_lo_ss(Z_AXIS,ARG3) + 1
      nzt = arg_hi_ss(T_AXIS,ARG3) - arg_lo_ss(T_AXIS,ARG3) + 1
      nz = max(nzx, nzy, nzz, nzt)

      ndimy = 0
      ndimz = 0
      DO 110 i = X_AXIS, T_AXIS
         IF (arg_hi_ss(i,ARG2) - arg_lo_ss(i,ARG2) .GT.0) 
     .       ndimy = ndimy + 1
         IF (arg_hi_ss(i,ARG3) - arg_lo_ss(i,ARG3) .GT.0) 
     .       ndimz= ndimz + 1
  110 CONTINUE

      IF (ny .NE. nz   .OR.  ndimy .GT. 1  .OR. ndimz .GT.1) THEN
         WRITE (err_msg, 10)
         GO TO 999
      ENDIF

   10 FORMAT(
     . 'Arguments 2 and 3 must be 1-dimensional lists of equal length')

*  Get y and z coordinates of the data to be sampled.

      CALL ef_get_coordinates(id, ARG1, Y_AXIS,
     .   arg_lo_ss(Y_AXIS, ARG1), arg_hi_ss(Y_AXIS, ARG1), yax)
      CALL ef_get_coordinates(id, ARG1, Z_AXIS,
     .   arg_lo_ss(Z_AXIS, ARG1), arg_hi_ss(Z_AXIS, ARG1), zax)

      i2 = arg_lo_ss(X_AXIS,ARG2)
      j2 = arg_lo_ss(Y_AXIS,ARG2)
      k2 = arg_lo_ss(Z_AXIS,ARG2)
      l2 = arg_lo_ss(T_AXIS,ARG2)

      i3 = arg_lo_ss(X_AXIS,ARG3)
      j3 = arg_lo_ss(Y_AXIS,ARG3)
      k3 = arg_lo_ss(Z_AXIS,ARG3)
      l3 = arg_lo_ss(T_AXIS,ARG3)

*  Check to see if input y or z  axis is modulo

      CALL ef_get_axis_info (id, ARG1, ax_name, ax_units, backward, 
     .                       modulo, regular)

      ylo = arg_lo_ss(Y_AXIS,ARG1)
      yhi = arg_hi_ss(Y_AXIS,ARG1)
      zlo = arg_lo_ss(Z_AXIS,ARG1)
      zhi = arg_hi_ss(Z_AXIS,ARG1)

      IF ( modulo(1) ) delmody = yax(yhi,1,1,1) - yax(ylo,1,1,1)
      IF ( modulo(2) ) delmodz = zax(zhi,1,1,1) - zax(zlo,1,1,1)

*  For each (ypt,zpt) pair, search the data array 
*   arg_1 for the nearest higher (y,z) grid coordinates.  Interpolate 
*   in 2 directions for the result.

      i2 = arg_lo_ss(X_AXIS,ARG2)
      j2 = arg_lo_ss(Y_AXIS,ARG2)
      k2 = arg_lo_ss(Z_AXIS,ARG2)
      l2 = arg_lo_ss(T_AXIS,ARG2)

      i3 = arg_lo_ss(X_AXIS,ARG3)
      j3 = arg_lo_ss(Y_AXIS,ARG3)
      k3 = arg_lo_ss(Z_AXIS,ARG3)
      l3 = arg_lo_ss(T_AXIS,ARG3)

      k = res_lo_ss(Z_AXIS)
      DO 500 j = res_lo_ss(Y_AXIS), res_hi_ss(Y_AXIS)

         jbot = ef_unspecified_int4	! Check if ypt points in xax range.
         jmatch = 0

	 ypt = arg_2(i2,j2,k2,l2)
         DO 100 j1 = arg_lo_ss(Y_AXIS,ARG1), arg_hi_ss(Y_AXIS,ARG1)
            IF (ypt .GE. yax(j1,1,1,1)) jbot = j1
            if (ypt .EQ. yax(j1,1,1,1)) jmatch = j1

cbf      may be some derivation from the exact value can be allowed:
cbf      if (ypt - yax(j1,1,1,1)).le.eps)   jmatch = j1

*  Locate the Y point within the range of modulo Y axis 

	    IF (modulo(2)) THEN
	       DO WHILE (ypt .GE. yax(yhi,1,1,1) ) 
                  ypt = ypt - delmody
	       ENDDO
	       DO WHILE (ypt .LT. yax(ylo,1,1,1) )
		  ypt = ypt + delmody
	       ENDDO
	    ENDIF

  100    CONTINUE

         j1 = arg_hi_ss(Y_AXIS,ARG1)
         IF (ypt .GT. yax(j1,1,1,1)) THEN
             jbot = ef_unspecified_int4		! ARG_2 ypt outside of range 
						! (non modulo)
         ENDIF

cbf       for matching the next neighbour is not of interest
         IF (jmatch .NE. 0) then
            jtop = jbot
         ELSE
            jtop = jbot + 1
         ENDIF
         IF (jbot .EQ. ef_unspecified_int4) jtop = jbot

cbf        analogously in z direction
         kbot = ef_unspecified_int4	! Check if zpt points in yax range.
         kmatch = 0

	 zpt = arg_3(i3,j3,k3,l3)
         DO 200 k1 = arg_lo_ss(Z_AXIS,ARG1), arg_hi_ss(Z_AXIS,ARG1)
            IF (zpt .GE. zax(k1,1,1,1) ) kbot = k1
            IF (zpt .EQ. zax(k1,1,1,1) ) kmatch = k1
cbf         IF (zpt - zax(k1,1,1,1) ) .LE. eps) kmatch = k1

*  Locate the Z point within the range of modulo Z axis 

	    IF (modulo(3)) THEN
	       DO WHILE (zpt .GE. zax(zhi,1,1,1) ) 
                  zpt = zpt - delmodz
	       ENDDO
	       DO WHILE (zpt .LT. zax(zlo,1,1,1) )
		  zpt = zpt + delmodz
	       ENDDO
	    ENDIF

  200    CONTINUE
         k1 = arg_hi_ss(Z_AXIS,ARG1)
         IF (arg_3(i3,j3,k3,l3) .GE. zax(k1,1,1,1) ) THEN
            kbot = ef_unspecified_int4		! ARG_3 zpt outside of range 
						! (non modulo)

         ENDIF

c         print *, ' ypt,zpt,jbot,kbot', ypt,zpt,jbot,kbot

         IF (kmatch .NE. 0) then
            ktop = kbot
         ELSE
            ktop = kbot + 1
         ENDIF
         IF (kbot .EQ. ef_unspecified_int4) ktop = kbot

         i1 = arg_lo_ss(X_AXIS,ARG1)
         DO 400 i = res_lo_ss(X_AXIS), res_hi_ss(X_AXIS)

            l1 = arg_lo_ss(T_AXIS,ARG1)
            l2 = arg_lo_ss(T_AXIS,ARG2)
            l3 = arg_lo_ss(T_AXIS,ARG3)
            DO 300 l = res_lo_ss(T_AXIS), res_hi_ss(T_AXIS)

*  First interpolate in y, getting values of the fcn at (y,kbot) and (y,ktop)

	       IF (jbot .EQ. ef_unspecified_int4  .OR.  
     .		   kbot .EQ. ef_unspecified_int4) THEN
                 result(i,j,k,l) = bad_flag_result
	       ELSE 
                  IF (jbot .GE. arg_lo_ss(Y_AXIS,ARG1)  .AND.
     .                jtop .LE. arg_hi_ss(Y_AXIS,ARG1) ) THEN

                     ybot = yax(jbot,1,1,1)
                     ytop = yax(jtop,1,1,1)

                     fbb = arg_1(i1,jbot,kbot,l1)
                     fbt = arg_1(i1,jtop,kbot,l1)	!
                     ftb = arg_1(i1,jbot,ktop,l1)	!
                     ftt = arg_1(i1,jtop,ktop,l1)

                     IF (fbb .NE. bad_flag(ARG1)  .AND.
     .                   ftb .NE. bad_flag(ARG1)  .AND.
     .                   fbt .NE. bad_flag(ARG1)  .AND.
     .                   ftt .NE. bad_flag(ARG1) ) THEN

cbf                 for matching x-axis no interpolation is need
                          if (jmatch.eq.0) then
                             fbot = fbb
                             ftop = fbt
                          else
                             frac = (ypt - ybot )/ (ytop - ybot)
                             fbot = fbb + frac* (ftb - fbb)
                             ftop = fbt + frac* (ftt - fbt)
                          endif

*  Now interpolate in z, getting value at (y,z)

                       IF (kbot .GE. arg_lo_ss(Z_AXIS,ARG1)  .AND.
     .                     ktop .LE. arg_hi_ss(Z_AXIS,ARG1) ) THEN
                          zbot = zax(kbot,1,1,1)
                          ztop = zax(ktop,1,1,1)

                          if(kmatch.eq.0) then
                             result(i,j,k,l) = fbot
                          else
                            frac = (zpt - zbot)/ (ztop-zbot)

                            result(i,j,k,l) = fbot + frac* 
     .                                         (ftop - fbot)

                          endif
                       ELSE
                           result(i,j,k,l) = bad_flag_result
                       ENDIF

                    ELSE
                        result(i,j,k,l) = bad_flag_result
                    ENDIF  ! bad_flag(ARG1) test
                  ENDIF	   ! fbb,ftp, etc not bad flags

	       ENDIF  ! jtop, ktop not ef_unspecified_int4

               l1 = l1 + arg_incr(T_AXIS,ARG1)

 300        CONTINUE

            i1 = i1 + arg_incr(X_AXIS,ARG1)
 400     CONTINUE

         i2 = i2 + arg_incr(X_AXIS,ARG2)
         j2 = j2 + arg_incr(Y_AXIS,ARG2)
         k2 = k2 + arg_incr(Z_AXIS,ARG2)
         l2 = l2 + arg_incr(T_AXIS,ARG2)

         i3 = i3 + arg_incr(X_AXIS,ARG3)
         j3 = j3 + arg_incr(Y_AXIS,ARG3)
         k3 = k3 + arg_incr(Z_AXIS,ARG3)
         l3 = l3 + arg_incr(T_AXIS,ARG3)
         k = k + res_incr(Z_AXIS)
500   CONTINUE


      RETURN
 999  CALL ef_bail_out (id, err_msg)

      END
