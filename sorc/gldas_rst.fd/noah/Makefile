SHELL   =/bin/sh
EXEC    =gldas_rst
LOPTS	= 
LIBS    =${NEMSIO_LIB} ${BACIO_LIB4} ${W3EMC_LIB4} ${W3NCO_LIB4}
OBJS = $(EXEC).o
SRCS = gldas_noah_rst.f
# *************************************************************************
all: $(SRCS)
	$(FC) $(FOPTS) $(LOPTS) ${SRCS} -o $(EXEC) $(LIBS)
clean:
	rm -f ${EXEC} *.o ../../../exec/$(EXEC)
install:
	mv ${EXEC} ../../../exec
