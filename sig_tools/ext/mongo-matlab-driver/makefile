OBJS=DllMain.o bson.o mongo.o net.o gridfs.o md5.o encoding.o numbers.o api_bson.o api_mongo.o api_gridfs.o
CC=gcc
MATLAB=/broad/software/nonfree/Linux/redhat_5_x86_64/pkgs/matlab_2012b
INCPATH=$(MATLAB)/extern/include
ARCH := $(shell getconf LONG_BIT)
LIB_32=-L$(MATLAB)/bin/glnx86
LIB_64=-L$(MATLAB)/bin/glnxa64
LIBS=$(LIB_$(ARCH)) -lmex -lmx 
CFLAGS=-Wall -fPIC -I$(INCPATH) -DMONGO_HAVE_STDINT

.c.o:
	$(CC) $(CFLAGS) -c $<

MongoMatlabDriver.so: $(OBJS)
	$(CC) -shared -o MongoMatlabDriver.so $(OBJS) $(LIBS)

