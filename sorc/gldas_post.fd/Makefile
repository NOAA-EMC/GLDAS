SHELL   =/bin/sh
EXEC    =gldas_post
FC	=ifort
INCNEMSIO=${NEMSIO_INC}
FOPTS	= -O -FR -I$(INCNEMSIO) -convert big_endian
LOPTS	= 
LIBS    =${NEMSIO_LIB} ${BACIO_LIB4} ${W3EMC_LIB4} ${W3NCO_LIB4}
#LIBS	=-L/nwprod/lib -lnemsio -lbacio_4 -lw3emc_4  -lw3nco_4
OBJS = $(EXEC).o
SRCS = $(EXEC).f
# *************************************************************************
all: $(SRCS)
	$(FC) $(FOPTS) $(LOPTS) ${SRCS} -o $(EXEC) $(LIBS)
clean:
	rm ${EXEC}
