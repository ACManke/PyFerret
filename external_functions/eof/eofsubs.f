

c -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

C  eofin_chel_gap from Billy Kessler.  
C  Ansley Manke 9/98  Change to have the bad-data flag "realbad" an argument
C                     and to test for .GT. realbad rather than .LT.
C                     Add argument pct_cutoff for where to stop the computations
C                     that normalize eigenvectors and compute time functions,
C                     and returning nout = number of functions to output.
C  Ansley Manke 8/99  Change dimension statements for arguments to be (*) or
C                     (NX,*), etc.  The work arrays in the calling functions
C                     now have extra space to accomodate I = 1,N... BB(I+1) in 
C                     QRSYM, for example.
C  Ansley Manke 10/00 Change bad-data flag "realbad"  to bad_flag_dat
C                     and a separate flag for bad_flag_result, the bad-data
C                     flag for the result.
C  Ansley Manke 1/01  declare all variables.
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c	eof_gap_sub4.f 
c	implements Chelton's '82 method for finding EOFs of gappy time series.
c	4 fixes a few imprecisions in earlier versions:
c		1) sets negative eigenvalues to eps = 1/10th smallest EV
c		2) blanks TAF if ALL data missing at a given time realization.
c	If no gaps, reduces to ordinary EOFs (but computationally wasteful).
c	Requires eigenvalue finder SUBROUTINEs in eofsub_2.for.
c	Gaps assumed to be marked by values = 1.e34.
c***************************************************************************

C..........SUBROUTINE EOFIN_CHEL_GAP 
c..........is a front end to the EOF SUBROUTINEs in eofsub_2.for.

c	Variables:
c	data(nx,nt)	I/O	original data.	Returned demeaned.
c	nx		I	number of spatial locations
c	nt		I	number of time realizations
c	val(nx)		O	eigenvalues (Lambda)
c	vec(nx,nx)	O	eigenvectors (Lambda*U). Same units as data.
c	taf(nx,nt)	O	time amplitude functions (V). Dimensionless.
c	pct(nx)		O	% variance represented by each EOF.
c	c(nx,nx)	O	work space for cov matrix (garbage output)

C..........Arrangement of output:
C					  VEC(position,EOF#)
C					  TAF(EOF#,time)
		
C---------------------------------------------------------------------
      SUBROUTINE EOFIN_CHEL_GAP (DATA,NX,NT,VAL,VEC,TAF,PCT,C, 
     +      eofwork, pct_cutoff, nout, bad_flag_dat, bad_flag_result,
     +      err_msg, ier)

        INTEGER nx
	REAL DATA(NX,*), PCT(*), VAL(*), VEC(NX,*),
     +            TAF(NX,*), C(NX,*)

      CHARACTER*(*) err_msg

      INTEGER nt, nout, ier, ix, i2, it, i, j, i1, ie, nx_compute, npr,
     .        ic, is
      REAL pct_cutoff, ct, eps, sumljgji, beta, tvar

      INCLUDE 'ferret_cmn/EF_Util.cmn'
      INCLUDE 'ferret_cmn/EF_mem_subsc.cmn'

      REAL eofwork(wrk9lox:wrk9hix, wrk9loy:wrk9hiy,
     .               wrk9loz:wrk9hiz, wrk9lot:wrk9hit)
      REAL bad_flag_dat, bad_flag_result

C---------------------------------------------------------------------
c.............initializations.


        ier = 0
	do 50 ix=1,nx
	val(ix)=0.
	pct(ix)=0.
	do 51 i2=1,nx
	vec(ix,i2)=0.
51	c(ix,i2)=0.
	do 52 it=1,nt
52	taf(ix,it)=0.
50	continue
C---------------------------------------------------------------------
C.................Find mean, demean DATA.
C.................Note PCT is used first as a dummy to save the mean.
	DO 100 I=1,NX
	ct=0.
	DO 110 J=1,NT
	if (data(i,j).GT.bad_flag_dat) then
		PCT(I)=PCT(I)+DATA(I,J)
		ct=ct+1.
	endif
110	continue
	if (ct.gt.0.) then
		pct(i)=pct(i)/ct
	else
	   write(err_msg,*) ' EOFIN_CHEL_GAP found the time series',
     .                     ' at ix=',i,' with no values.'
           ier = 1
	   return
	endif
	DO 120 J=1,NT
	if (data(i,j).GT.bad_flag_dat) then
		DATA(I,J)=DATA(I,J)-PCT(I)
	endif
120	continue
100	CONTINUE
C--------------------------------------------------------------------
C.................Form the mean product matrix.
	DO 210 I1=1,NX
	DO 210 I2=1,NX

	ct=0.
	DO 200 J=1,NT
	if (data(i1,j).GT.bad_flag_dat .and. data(i2,j).GT.bad_flag_dat) then
		ct=ct+1.
		C(I1,I2) = C(I1,I2) + DATA(I1,J) * DATA(I2,J)
	endif
200	continue

	if (ct.gt.0.) then
		c(i1,i2)=c(i1,i2)/ct
	else
           write(err_msg,*) ' EOFIN_CHEL_GAP found no overlapping',
     .       ' values in two time series at EOF-1D-coordinates ', 
     .       i1,i2, ' Will be a zero in covariance matrix'
           ier = 1
           return
	endif

210	CONTINUE
C------------------------------------------------------------------------
C.................Call the subroutines which do the work.

	CALL QRSYM(C,NX,VAL,VEC, eofwork) 

C.................VEC(IS,IE) is arranged so that IS indexes the space
C.................dimension of each eigenvector and IE the EOF number.
C------------------------------------------------------------------------
c...................check for negative eigenvalues, set to eps.
	do 250 ie=1,nx
250	if (val(ie).lt.0.) GOTO 251
	GOTO 252

251	continue
cc 251	write(6,*) 'Found a negative eigenvalue. EV#',ie,
cc     .        ' Further checking ...'
cc 251	write(6,*) 'Found a negative eigenvalue. Further checking ...'

	eps=1.e20
	do 255 ie=1,nx
255	if (abs(val(ie)).lt.eps) eps=abs(val(ie))
	eps=eps/10.
cc	write(6,*) 'Setting epsilon to',eps
cc	write(6,*) '= 1/10th of the smallest eigenvalue'
	do 256 ie=1,nx
	if (val(ie).lt.0.) then
cc		write(6,*) 'Setting EV #',ie,' =',val(ie),
cc     .					' to epsilon (=',eps,')'
		val(ie)=eps
	endif
256	continue
252	continue

C----------------------------------------------------------------------
C !ACM  Use pct_cutoff to determine how many TAF's to compute.  Array pct
C       is then used as a dummy array below, and we will compute it again
C       before returning.
C.................Find the percentage of total variance accounted for by
C.................each eigenvector.
c.................Place this at the end to be able to use pct as dummy
c.................for counting missing data in TAF calculation.
	TVAR=0.0
        nx_compute = 0
	DO 1220 I=1,NX
1220	TVAR=TVAR+VAL(I)
	DO 1221 I=1,NX
	PCT(I)=100.*ABS(VAL(I)/TVAR)
1221	IF (PCT(I) .GE. pct_cutoff) nx_compute = I

C------------------------------------------------------------------------
C.................Renormalize EOFs.
C.................Thus EOFs have units of data, while time amplitude functions
C.................are dimensionless.
C.................Thus the sum of the values of a given EOF = SQRT(eigenvalue).
C.................And the mean of a given TAF = 1.
C-------------------------------------------------------------------------
C.................First compute the time amplitude function from the data.
C.................Renormalize each TAF by dividing by SQRT of its eigenvalue.

c...........................loop over time

        nx_compute = nx		! acm 1/01  testing time routine takes
        nout = nx_compute

	DO 350 J=1,NT
	npr = nt/ 10 
        if (nt .gt. 100) npr = (npr/ 10) * 10     

c............find out if any gaps exist at this time.
c............use ic to count them and pct(nx) to keep track of where they are.
	ic=0
	do 400 is=1,nx
	if (data(is,j).GT.bad_flag_dat) then
		ic=ic+1
		pct(is)=0.
	else
		pct(is)=1.
	endif
400	continue

c..............if no blanks at this time, compute TAF as usual.
	if (ic.eq.nx) then
c................................loop over EOF numbers, then over space.
		DO 360 IE=1,NX_compute

		DO 370 IS=1,NX
370		TAF(IE,J) = TAF(IE,J) + 
     .			    VEC(IS,IE)*DATA(IS,J)
360		CONTINUE
	elseif (ic.eq.0) then
c..............If there are NO data values at time j, then blank the TAF.
		do 450 ie=1,nx
450		taf(ie,j)=bad_flag_result
	else
c.............If there are some blanks, then use Chelton's estimate Beta_i(t).
c.............Now use c(nx,nx) as dummy to keep Chelton's Gamma_ji.
c.............Fill c(i,j), where i and j are both EOF #s. 
c.............Sum over MISSING data points only.

		do 410 i1=1,nx_compute
		do 410 i2=1,nx
		   c(i1,i2)=0.
		   do 415 ix=1,nx
415		   if (pct(ix).eq.1)
     .			c(i1,i2)=c(i1,i2)+vec(ix,i1)*vec(ix,i2)
410		continue

c..................Loop over EOF numbers.
		do 420 ie=1,nx_compute

c......................Find Beta_i(t) from Gamma_ij.
c......................Also need the sum of Lambda_j*Gamma_ji**2 over all j.ne.i

c.......................loop 430 sums over space.
		   sumljgji=0.
                   do 430 i2=1,nx
430                if (i2.ne.ie) sumljgji=sumljgji+val(i2)*c(i2,ie)**2
c
c  Billy said to replace the loop below with the one above. This is the
c    problem that Mick spotted. 
c
c		   do 430 i2=1,nx
c		   if (i2.eq.ie) GOTO 431
c 430		   sumljgji=sumljgji+val(i2)*c(i2,ie)**2
c
431		   continue

c.....................find beta.
		   beta = ( (1.-c(ie,ie)) * val(ie) ) / 
     .			 ( val(ie) * (1.-c(ie,ie))**2 + sumljgji )

c...................Now find TAF. Summation in space over existing points only.
		   do 440 is=1,nx
440			if (pct(is).eq.0.) taf(ie,j) = taf(ie,j) + 
     .			   	beta * vec(is,ie) * data(is,j)

420		continue


	endif
		
350	CONTINUE

C-------------------------------------------------------------------------
C.................Renormalize each EOF by the SQRT of its eigenvalue.
c.................loop over EOF numbers, then over space.
	DO 300 IE=1,NX_compute
	do 315 j=1,nt

315	if (taf(ie,j) .GT. bad_flag_dat) taf(ie,j)=taf(ie,j)/sqrt(val(ie))
	DO 316 IS=1,NX
316	VEC(IS,IE) = VEC(IS,IE)*SQRT(VAL(IE))
300	CONTINUE
C----------------------------------------------------------------------
C.................Find the percentage of total variance accounted for by
C.................each eigenvector.
c.................Place this at the end to be able to use pct as dummy
c.................for counting missing data in TAF calculation.
	TVAR=0.0
	DO 220 I=1,NX
220	TVAR=TVAR+VAL(I)
	DO 221 I=1,NX
221	PCT(I)=100.*ABS(VAL(I)/TVAR)
C------------------------------------------------------------------------
	RETURN
	END

C************************************************************************

      SUBROUTINE QRSYM (A,N,E,X, eofwork)

      INTEGER N
      REAL A(N,*),E(*),X(N,*)
c      DIMENSION ALPHA(4000),BETA(4000),BB(4000)
*  
* 5/99 ACM  Use a work array eofwork rather than explicitly dimensioned
*           arrays ALPHA, BETA, BB, and P (originally declared in HOUSEH)

      INCLUDE 'ferret_cmn/EF_Util.cmn'
      INCLUDE 'ferret_cmn/EF_mem_subsc.cmn'

      REAL eofwork(wrk9lox:wrk9hix, wrk9loy:wrk9hiy,
     .               wrk9loz:wrk9hiz, wrk9lot:wrk9hit)

      INTEGER nb
      REAL rnorm, eps


      nb=n

      CALL HOUSEH(A,N,eofwork(1,1,1,1),eofwork(1,2,1,1),NB,
     .            eofwork(1,4,1,1))
      CALL QRSTD (eofwork(1,1,1,1),eofwork(1,2,1,1),N,E,
     .            eofwork(1,3,1,1),RNORM,EPS)

      CALL TRIDIN(eofwork(1,1,1,1),eofwork(1,2,1,1),N,E,RNORM,
     .            N,2.0**(-48),X,NB)

      CALL BACKS(eofwork(1,2,1,1),A,N,X,N,EPS,NB)

c      nb=n
c      CALL HOUSEH(A,N,ALPHA,BETA,NB)
c      CALL QRSTD (ALPHA,BETA,N,E,BB,RNORM,EPS)
c      CALL TRIDIN(ALPHA,BETA,N,E,RNORM,N,2.0**(-48),X,NB)
c      CALL BACKS(BETA,A,N,X,N,EPS,NB)

      RETURN
      END

C**********************************************************************

      SUBROUTINE HOUSEH (G,N,A,B,NB, p)
      INTEGER NB
      REAL G(NB,*),A(*),B(*)

c      DIMENSION P(2000)
      REAL P(*)

      INTEGER n, n2, k, k1, i, j, i1
      REAL sum, sigma, absb, alpha, beta, gamma, t

      N2=N-2
      IF(N2)45,44,2
    2 DO 43 K=1,N2
      A(K)=G(K,K)
      SUM=0
      K1=K+1
      DO 8 I=K1,N
    8 SUM=SUM+G(I,K)**2
      SIGMA=SUM
      ABSB=SQRT(SIGMA)
      ALPHA=G(K+1,K)
      BETA=-ABSB
      IF(ALPHA)15,16,16
   15 BETA=ABSB
   16 B(K)=BETA
      IF(SIGMA)18,43,18
   18 GAMMA=1/(SIGMA-ALPHA*BETA)
      G(K+1,K)=ALPHA-BETA		! change C so now not Mean Prod Matrix
      DO 27 I=K1,N
      SUM=0
      DO 23 J=K1,I
   23 SUM=SUM+G(I,J)*G(J,K)
      IF(I.EQ.N)GO TO 27
      I1=I+1
      DO 26 J=I1,N
   26 SUM=SUM+G(J,I)*G(J,K)
   27 P(I)=GAMMA*SUM
      SUM=0
      DO 30 I=K1,N
   30 SUM=SUM+G(I,K)*P(I)
      T=0.5*GAMMA*SUM
      DO 32 I=K1,N
   32 P(I)=P(I)-T*G(I,K)
      DO 35 I=K1,N
      DO 35 J=K1,I
   35 G(I,J)=G(I,J)-G(I,K)*P(J)-P(I)*G(J,K)
   43 CONTINUE
   44 A(N-1)=G(N-1,N-1)
      B(N-1)=G(N,N-1)
   45 A(N)=G(N,N)
      B(N)=0.0
      RETURN
      END

C************************************************************************

      SUBROUTINE QRSTD (ALPHA,BETA,N,E,BB,RNORM,EPS)
      REAL ALPHA(*),BETA(*),E(*),BB(*)

      INTEGER n, i, k, m, n1, i1, j
      REAL eta, delta, t, r, w, c, s, shift, g, p, ek1, rnorm, eps


C W.KAHAN AND J.VARAH, TWO WORKING ALGORITHMS FOR THE EIGENVALUES OF A
C SYMMETRIC TRIDIAGONAL MATRIX. TECHNICAL REPORT NO. CS43, AUGUST 11,
C 1966. COMP.SC.DEPT. STANFORD UNIVERSITY.


      DO 2 I=1,N
      E(I)=ALPHA(I)
      BB(I+1)=BETA(I)**2
    2 continue
      BB(1)=0.0
      BB(N+1)=0.0
C INFINITY NORM OF TRIDIAGONAL MATRIX
      RNORM=0.0
      DO 5 I=1,N
    5 RNORM=AMAX1(RNORM,SQRT(BB(I))+ABS(E(I))+SQRT(BB(I+1)))
C ETA = RELATIVE MACHINE PRECISION
      ETA=2.0**(-48)
      DELTA=ETA*RNORM
      EPS=DELTA**2
      IF (EPS.EQ.0) RETURN
      K=N
    6 M=K
      IF(M.LE.0)GO TO 56
    8 K=K-1
      IF(BB(K+1).GE.EPS)GO TO 8
C NEXT
      IF(K.NE.M-1)GO TO 13
      BB(K+1)=0.0
      GO TO 6
C TWOBY2
   13 T=E(M)-E(M-1)
      R=BB(M)
      IF(K.GE.M-2)GO TO 22
      W=BB(M-1)
      C=T**2
      S=R/(C+W)
      IF(S*(W+S*C).GE.EPS)GO TO 22
      M=M-1
      BB(M+1)=0.0
      GO TO 13
C END NEGLIGIBLE BB
   22 IF(ABS(T).GE.DELTA)GO TO 25
      S=SQRT(R)
      GO TO 28
   25 W=2.0/T
      S=W*R/(SQRT(W**2*R+1.0)+1.0)
   28 IF(K.NE.M-2)GO TO 33
      E(M)=E(M)+S
      E(M-1)=E(M-1)-S
      BB(K+1)=0.0
      GO TO 6
C DO A QR STEP ON ROWS AND COLUMNS K+1 THROUGH M
   33 SHIFT=E(M)+S
      IF(ABS(T).GE.DELTA)GO TO 37
      W=E(M-1)-S
      IF(ABS(W).LT.ABS(SHIFT))SHIFT=W
   37 S=0.0
      G=E(K+1)-SHIFT
      C=1.0
      GO TO 45
C LOOP
   40 C=P/T
      S=W/T
      W=G
      EK1=E(K+1)
      G=C*(EK1-SHIFT)-S*W
      E(K)=(W-G)+EK1
C ENTRY
   45 IF(ABS(G).GE.DELTA)GO TO 48
      IF(G.GE.0.0)GO TO 47
      G=G-C*DELTA
      GO TO 48
   47 G=G+C*DELTA
   48 P=G**2/C
      K=K+1
      W=BB(K+1)
      T=W+P
      BB(K)=S*T
   50 IF(K.LT.M)GO TO 40
      E(K)=G+SHIFT
      GO TO 6
C SORT
   56 IF(N.EQ.1)RETURN
      N1=N-1
      DO 70 I=1,N1
      K=I
      T=E(I)
      I1=I+1
      DO 62 J=I1,N
      IF(E(J).LE.T)GO TO 62
      T=E(J)
      K=J
   62 CONTINUE
      IF(I.EQ.K)GO TO 70
      E(K)=E(I)
      E(I)=T
   70 CONTINUE
      RETURN
      END

C*************************************************************************

      SUBROUTINE TRIDIN (C,B,N,W,NORM,M1,MACHEPS,Z,NB)

      INTEGER nb, nminus1, ii
      REAL C(*),B(*),W(*),Z(NB,*)

C J.H.WILKINSON, CALCULATION OF THE EIGENVECTORS OF A SYMMETRIC
C TRIDIAGONAL MATRIX BY INVERSE ITERATION. NUMERISCHE MATHEMATIK 4,
C 368-376 (1962)

      REAL M(4000),P(4000),Q(4000),R(4000),INT(4000),X(4002)
      INTEGER N,M1
      REAL NORM,MACHEPS

      INTEGER I,J
c      REAL BI,BI1,Z1,LAMBDA,U,S,V,H,EPS,ETA
      REAL BI,BI1,LAMBDA,U,V,H,EPS,ETA

      IF (N-1)10,20,30
   20 Z(1,1)=1.
   10 RETURN
   30 CONTINUE
      LAMBDA=NORM
      EPS=MACHEPS*NORM
      DO 90 J=1,M1
      LAMBDA=LAMBDA-EPS
      IF(W(J).LT.LAMBDA)LAMBDA=W(J)
      U=C(1)-LAMBDA
      V=B(1)
      IF(V.EQ.0)V=EPS
      NMINUS1=N-1
      DO 60 I=1,NMINUS1
      BI=B(I)
      IF(BI.EQ.0)BI=EPS
      BI1=B(I+1)
      IF(BI1.EQ.0)BI1=EPS
      IF(ABS(BI).LT.ABS(U))GO TO 50
      M(I+1)=U/BI
      IF((M(I+1).EQ.0).AND.(BI.LE.EPS))M(I+1)=1
      P(I)=BI
      Q(I)=C(I+1)-LAMBDA
      R(I)=BI1
      U=V-M(I+1)*Q(I)
      V=-M(I+1)*R(I)
      INT(I+1)=+1
      GO TO 60
   50 M(I+1)=BI/U
      P(I)=U
      Q(I)=V
      R(I)=0
      U=C(I+1)-LAMBDA-M(I+1)*V
      V=BI1
      INT(I+1)=-1
   60 CONTINUE
      P(N)=U
      Q(N)=0
      R(N)=0
      X(N+1)=0
      X(N+2)=0
      H=0
      ETA=1.0/N
      DO 67 II=1,N
      I=N-II+1
      U=ETA-Q(I)*X(I+1)-R(I)*X(I+2)
      IF(P(I).NE.0)GO TO 65
      X(I)=U/EPS
      GO TO 66
   65 X(I)=U/P(I)
   66 H=H+ABS(X(I))
   67 CONTINUE
      DO 68 I=1,N
   68 X(I)=X(I)/H
      DO 75 I=2,N
      IF(INT(I).LE.0)GO TO 70
      U=X(I-1)
      X(I-1)=X(I)
      X(I)=U-M(I)*X(I-1)
      GO TO 75
   70 X(I)=X(I)-M(I)*X(I-1)
   75 CONTINUE
      H=0
      DO 82 II=1,N
      I=N-II+1
      U=X(I)-Q(I)*X(I+1)-R(I)*X(I+2)
      IF(P(I).NE.0)GO TO 80
      X(I)=U/EPS
      GO TO 81
   80 X(I)=U/P(I)
C   81 H=H+X(I)**2
81	IF (X(I).GT.1.E10) THEN
		H=1.E20
	ELSE
		H=H+X(I)**2
	ENDIF
   82 CONTINUE
      H=SQRT(H)
C STORE VECTORS AS COLUMNS
      DO 85 I=1,N
   85 Z(I,J)=X(I)/H
   90 CONTINUE
      RETURN
      END

C**********************************************************************

      SUBROUTINE BACKS (BETA,A,N,X,M1,EPS,NB)
      INTEGER n, nb, m1 
      REAL BETA(*), A(NB,*), X(NB,*), EPS

      INTEGER j, kk, k, k1, i
      REAL s


C BACKTRANSFORMATION

   73 IF (N.LE.2)RETURN
      DO 90 J=1,M1
      DO 85 KK=3,N
      K=N-KK+1
   76 IF (ABS(BETA(K)).LE.EPS) GO TO 85
      S=0.0
      K1=K+1
      DO 75 I=K1,N
   75 S=S+A(I,K)*X(I,J)
      S=S/(BETA(K)*A(K1,K))
      DO 80 I=K1,N
   80 X(I,J)=X(I,J)+S*A(I,K)
   85 CONTINUE
   90 CONTINUE

      RETURN
      END
