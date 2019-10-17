SHELL   =/bin/sh
EXEC    =gldas_forcing
LOPTS	= 
LIBS    =${BACIO_LIB4} ${W3NCO_LIB4}
OBJS = $(EXEC).o
SRCS = $(EXEC).f
# *************************************************************************
all: $(SRCS)
	$(FC) $(FOPTS) $(LOPTS) ${SRCS} -o $(EXEC) $(LIBS)
clean:
	rm -f ${EXEC} *.o ../../exec/$(EXEC)
install:
	mv $(EXEC) ../../exec
