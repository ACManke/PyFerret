#
# Makefile for Ferret External Functions
#
# January 20 1998
# Jonathan Callahan
#
# dec-00 adapted for "godae_obs" function
# ACM 2/2001

#
# include site specific macro definitions
#
include ../ef_utility/site_specific.mk

#
# include platform specific macro definitions
#
include ../ef_utility/platform_specific.mk.$(BUILDTYPE)

#
# Macros
#

.SUFFIXES: .so

GOB_OBJS = ocn_obs.o

#
# Rules
#

.c.so:
	$(CC) $(CFLAGS) -c $<
	$(LD) $(LD_DYN_FLAGS) $(GOB_OBJS) $*.o $(SYSLIBS) -o $*.so

.F.so:
	$(FC) $(FFLAGS) -c $<
	$(LD) $(LD_DYN_FLAGS) $(GOB_OBJS) $*.o $(SYSLIBS) -o $*.so

#
# Targets
#

all:	ocn_obs.o godae_obs.o godae_obs.so

debug:
	$(MAKE) "FFLAGS = $(FFLAGS) $(FFLAGS_DEBUG)" "CFLAGS = $(CFLAGS) $(CFLAGS_DEBUG)" all

install:
	cp *.so $(FER_LOCAL_EXTFCNS)

clean:
	-rm -f *.o *.so

#
# End of Makefile
#
