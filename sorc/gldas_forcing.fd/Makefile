SHELL   =/bin/sh
EXEC    =gldas_forcing
FC	=ifort
FOPTS	= -O -FR 
LOPTS	= 
LIBS    =${BACIO_LIB4} ${W3NCO_LIB4}
#LIBS	=-L/nwprod/lib -lbacio_4 -lw3nco_4
OBJS = $(EXEC).o
SRCS = $(EXEC).f
# *************************************************************************
all: $(SRCS)
	$(FC) $(FOPTS) $(LOPTS) ${SRCS} -o $(EXEC) $(LIBS)
clean:
	\rm ${EXEC}
