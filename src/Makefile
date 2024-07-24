# src/Makefile

EXTENSION = pg_cld2
EXTVERSION = 1.0.0

PG_CONFIG = pg_config
PG_CPPFLAGS = $(shell $(PG_CONFIG) --cppflags)
PG_LIBS = $(shell $(PG_CONFIG) --libs)
PG_INCLUDEDIR_SERVER = $(shell $(PG_CONFIG) --includedir-server)
PG_PKGLIBDIR = $(shell $(PG_CONFIG) --pkglibdir)
PG_LIBDIR = $(shell $(PG_CONFIG) --libdir)
PGXS = $(shell $(PG_CONFIG) --pgxs)

GPPV = $(shell g++ -dumpversion | cut -f1 -d.)
CXXFLAGS = -I$(PG_PKGLIBDIR) -I$(LIBDIR)
#-I/usr/include/c++/$(GPPV) -I/usr/include/x86_64-linux-gnu/c++/$(GPPV)
CFLAGS = $(PG_CPPFLAGS) -I$(PG_INCLUDEDIR_SERVER) -I$(PG_PKGLIBDIR) -I$(LIBDIR)

# Default target
all: pg_cld2.so

pg_cld2.so: pg_cld2.o
	g++ $(CXXFLAGS) -shared -o $@ $^ $(PG_LIBS) $(LD_FLAGS)

pg_cld2.o: pg_cld2.c
	g++ $(CFLAGS) -c -o $@ $<

clean:
	rm -f *.o *.so
