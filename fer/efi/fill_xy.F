* fill_xy.F
*
* Martin Schmidt
* Sept. 2001
*
* This function fill missing values by averaging over the neigbourhood
*
* *acm*  v6.8 6/19/2012 fix bug in loop 102, setting bad flags
*
*
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
* axis_influence     Are this argument''s axes the same as the result grid?
*                       ( YES, NO )
*
* axis_extend       How much does Ferret need to extend arg limits relative to result 
*

      SUBROUTINE fill_xy_init(id)

      IMPLICIT NONE
      INCLUDE 'EF_Util.cmn'

      INTEGER id, arg

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      CALL ef_set_desc(id,
     . 'fills missing values with average nearest neighbour values' )

      CALL ef_set_num_args(id, 3)
      CALL ef_set_axis_inheritance_6d(id,
     .                                IMPLIED_BY_ARGS, IMPLIED_BY_ARGS,
     .                                IMPLIED_BY_ARGS, IMPLIED_BY_ARGS,
     .                                IMPLIED_BY_ARGS, IMPLIED_BY_ARGS)
      CALL ef_set_piecemeal_ok_6d(id, NO, NO, NO, NO, NO, NO)

      arg = 1
      CALL ef_set_arg_name(id, arg, 'DATA')
      CALL ef_set_arg_unit(id, arg, ' ')
      CALL ef_set_arg_desc(id, arg, 'this arg is filled')
      CALL ef_set_axis_influence_6d(id, arg,
     .                              YES, YES, YES, YES, YES, YES)

      arg = 2
      CALL ef_set_arg_name(id, arg, 'MASK')
      CALL ef_set_arg_unit(id, arg, ' ')
      CALL ef_set_arg_desc(id, arg, 
     &     'mask (1 -> fill, missing -> do not fill)')
      CALL ef_set_axis_influence_6d(id, arg,
     .                              YES, YES, YES, YES, YES, YES)

      arg = 3
      CALL ef_set_arg_name(id, arg, 'N')
      CALL ef_set_arg_unit(id, arg, ' ')
      CALL ef_set_arg_desc(id, arg, 'the maximum number of fill-passes')
      CALL ef_set_axis_influence_6d(id, arg,
     .                              NO, NO, NO, NO, NO, NO)
*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END


*
* In this subroutine we compute the result
*
      SUBROUTINE fill_xy_compute(id, arg_1, arg_2, arg_3, result)

      IMPLICIT NONE
      INCLUDE 'EF_Util.cmn'
      INCLUDE 'EF_mem_subsc.cmn'

      INTEGER id

      REAL arg_1(mem1lox:mem1hix, mem1loy:mem1hiy, mem1loz:mem1hiz, 
     .           mem1lot:mem1hit, mem1loe:mem1hie, mem1lof:mem1hif)
      REAL arg_2(mem2lox:mem2hix, mem2loy:mem2hiy, mem2loz:mem2hiz, 
     .           mem2lot:mem2hit, mem2loe:mem2hie, mem2lof:mem2hif)
      REAL arg_3(mem3lox:mem3hix, mem3loy:mem3hiy, mem3loz:mem3hiz, 
     .           mem3lot:mem3hit, mem3loe:mem3hie, mem3lof:mem3hif)


      REAL result(memreslox:memreshix, memresloy:memreshiy, 
     .            memresloz:memreshiz, memreslot:memreshit,
     .            memresloe:memreshie, memreslof:memreshif)

* After initialization, the 'res_' arrays contain indexing information 
* for the result axes.  The 'arg_' arrays will contain the indexing 
* information for each variable''s axes. 

      INTEGER res_lo_ss(6),
     .        res_hi_ss(6),
     .        res_incr (6)
      INTEGER arg_lo_ss(6,EF_MAX_ARGS),
     .        arg_hi_ss(6,EF_MAX_ARGS),
     .        arg_incr (6,EF_MAX_ARGS)

      REAL bad_flag(EF_MAX_ARGS), bad_flag_result

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      REAL work_old(mem1lox:mem1hix, mem1loy:mem1hiy)
      REAL work_new(mem1lox:mem1hix, mem1loy:mem1hiy)

      INTEGER i, j, k, l, m, n
      INTEGER i1, j1, k1, l1, m1, n1
      INTEGER i2, j2, k2, l2, m2, n2
      INTEGER i3, j3, k3, l3, m3, n3
      integer iavr, is, js, icl, icr, jcl, jcu
      integer npass, npassmax
      real    tavr
      logical ready, not_land

      CALL ef_get_res_subscripts_6d(id, res_lo_ss, res_hi_ss, res_incr)
      CALL ef_get_arg_subscripts_6d(id, arg_lo_ss, arg_hi_ss, arg_incr)
      CALL ef_get_bad_flags(id, bad_flag, bad_flag_result)

      n1 = arg_lo_ss(F_AXIS,ARG1)
      n2 = arg_lo_ss(F_AXIS,ARG2)
      n3 = arg_lo_ss(F_AXIS,ARG3)
      DO 600 n=res_lo_ss(F_AXIS), res_hi_ss(F_AXIS)

      m1 = arg_lo_ss(E_AXIS,ARG1)
      m2 = arg_lo_ss(E_AXIS,ARG2)
      m3 = arg_lo_ss(E_AXIS,ARG3)
      DO 500 m=res_lo_ss(E_AXIS), res_hi_ss(E_AXIS)

      l1 = arg_lo_ss(T_AXIS,ARG1)
      l2 = arg_lo_ss(T_AXIS,ARG2)
      l3 = arg_lo_ss(T_AXIS,ARG3)
      DO 400 l=res_lo_ss(T_AXIS), res_hi_ss(T_AXIS)

         k1 = arg_lo_ss(Z_AXIS,ARG1)
         k2 = arg_lo_ss(Z_AXIS,ARG2)
         k3 = arg_lo_ss(Z_AXIS,ARG3)
         DO 300 k=res_lo_ss(Z_AXIS), res_hi_ss(Z_AXIS)

            ready = .false.
            j1 = arg_lo_ss(Y_AXIS,ARG1)
            DO j=res_lo_ss(Y_AXIS), res_hi_ss(Y_AXIS)
               i1 = arg_lo_ss(X_AXIS,ARG1)
               DO i=res_lo_ss(X_AXIS), res_hi_ss(X_AXIS)
                  work_new(i1,j1) = arg_1(i1,j1,k1,l1,m1,n1)
                  i1 = i1 + arg_incr(X_AXIS,ARG1)
               enddo
               j1 = j1 + arg_incr(Y_AXIS,ARG1)
            enddo
            npass = 0
            i3 = arg_lo_ss(X_AXIS,ARG3)
            j3 = arg_lo_ss(Y_AXIS,ARG3)
            npassmax = arg_3(i3,j3,k3,l3,m3,n3)
            do while (.not.ready)
               ready = .true.
               j1 = arg_lo_ss(Y_AXIS,ARG1)
               DO j=res_lo_ss(Y_AXIS), res_hi_ss(Y_AXIS)
                  i1 = arg_lo_ss(X_AXIS,ARG1)
                  DO i=res_lo_ss(X_AXIS), res_hi_ss(X_AXIS)
                     work_old(i1,j1) =work_new(i1,j1)
                     i1 = i1 + arg_incr(X_AXIS,ARG1)
                  enddo
                  j1 = j1 + arg_incr(Y_AXIS,ARG1)
               enddo
               j1 = arg_lo_ss(Y_AXIS,ARG1)
               j2 = arg_lo_ss(Y_AXIS,ARG2)
               DO 201 j=res_lo_ss(Y_AXIS), res_hi_ss(Y_AXIS)
                  i1 = arg_lo_ss(X_AXIS,ARG1)
                  i2 = arg_lo_ss(X_AXIS,ARG2)
                  DO 101 i=res_lo_ss(X_AXIS), res_hi_ss(X_AXIS)
                     if ( arg_2(i2,j2,k2,l2,m2,n2) .ne. bad_flag(2)
     &                    .and. work_old(i1,j1) .eq. bad_flag(1) ) then
                        tavr= 0.
                        iavr= 0
                        icl = max0(mem1lox,i1-1)
                        icr = min0(mem1hix,i1+1)
                        jcl = max0(mem1loy,j1-1)
                        jcu = min0(mem1hiy,j1+1)
                        do is=icl, icr
                           do js=jcl, jcu
                              if(work_old(is,js).ne.bad_flag(1)) then
                                 tavr=tavr+work_old(is,js)
                                 iavr=iavr+1
                              endif
                           enddo
                        enddo
! If valid surrounding points have been found, replace the missing value
! with the average over the neigbouring points
! Since something has changed, a new pass is required -> ready = .false.
                        if (iavr.ne.0) then
                           if (iavr.eq.1) then
! If the only found point is at the corner, an ill posed
! cellular automaton has to be avoided
                              if (work_old(icl,jcu).eq.bad_flag(1).and.
     &                            work_old(icr,jcu).eq.bad_flag(1).and.
     &                            work_old(icr,jcl).eq.bad_flag(1).and.
     &                            work_old(icl,jcl).eq.bad_flag(1)) then
                                 work_new(i1,j1)=tavr/iavr
                                 ready = .false.
                              endif
                           else
                              work_new(i1,j1)=tavr/iavr
                              ready = .false.
                           endif
                        endif
                     endif
                     i1 = i1 + arg_incr(X_AXIS,ARG1)
                     i2 = i2 + arg_incr(X_AXIS,ARG2)
 101              CONTINUE
                  j1 = j1 + arg_incr(Y_AXIS,ARG1)
                  j2 = j2 + arg_incr(Y_AXIS,ARG2)
 201           CONTINUE
               npass = npass + 1
               if (npass.eq.npassmax) ready = .true.
            enddo
            j1 = arg_lo_ss(Y_AXIS,ARG1)
            DO 202 j=res_lo_ss(Y_AXIS), res_hi_ss(Y_AXIS)
               i1 = arg_lo_ss(X_AXIS,ARG1)
               DO 102 i=res_lo_ss(X_AXIS), res_hi_ss(X_AXIS)
                  IF (work_new(i1,j1) .NE. bad_flag(1)) THEN
                     result(i,j,k,l,m,n) = work_new(i1,j1)
                  ELSE
                     result(i,j,k,l,m,n) = bad_flag_result
                  ENDIF
                  i1 = i1 + arg_incr(X_AXIS,ARG1)
 102           CONTINUE
               j1 = j1 + arg_incr(Y_AXIS,ARG1)
 202        CONTINUE

            k1 = k1 + arg_incr(Z_AXIS,ARG1)
            k2 = k2 + arg_incr(Z_AXIS,ARG2)
 300     CONTINUE
         l1 = l1 + arg_incr(T_AXIS,ARG1)
         l2 = l2 + arg_incr(T_AXIS,ARG2)
 400  CONTINUE
         m1 = m1 + arg_incr(E_AXIS,ARG1)
         m2 = m2 + arg_incr(E_AXIS,ARG2)
 500  CONTINUE
         n1 = n1 + arg_incr(F_AXIS,ARG1)
         n2 = n2 + arg_incr(F_AXIS,ARG2)
 600  CONTINUE
      
*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END
