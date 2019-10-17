SHELL   =/bin/sh
EXEC    =gldas_post
LOPTS	= 
LIBS    =${NEMSIO_LIB} ${BACIO_LIB4} ${W3EMC_LIB4} ${W3NCO_LIB4}
OBJS = $(EXEC).o
SRCS = $(EXEC).f
# *************************************************************************
all: $(SRCS)
	$(FC) $(FOPTS) $(LOPTS) ${SRCS} -o $(EXEC) $(LIBS)
clean:
	rm -f ${EXEC} *.o ../../exec/$(EXEC)
install:
	mv ${EXEC} ../../exec
