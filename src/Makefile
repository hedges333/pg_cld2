PG_CONFIG = pg_config
PG_CONFIG_OUTPUT := $(shell $(PG_CONFIG) --configure)
BINDIR := $(shell $(PG_CONFIG) --bindir)
DOCDIR := $(shell $(PG_CONFIG) --docdir)
HTMLDIR := $(shell $(PG_CONFIG) --htmldir)
INCLUDEDIR := $(shell $(PG_CONFIG) --includedir)
PKGINCLUDEDIR := $(shell $(PG_CONFIG) --pkgincludedir)
INCLUDEDIR_SERVER := $(shell $(PG_CONFIG) --includedir-server)
LIBDIR := $(shell $(PG_CONFIG) --libdir)
PKGLIBDIR := $(shell $(PG_CONFIG) --pkglibdir)
LOCALEDIR := $(shell $(PG_CONFIG) --localedir)
MANDIR := $(shell $(PG_CONFIG) --mandir)
SHAREDIR := $(shell $(PG_CONFIG) --sharedir)
SYSCONFDIR := $(shell $(PG_CONFIG) --sysconfdir)
PGXS := $(shell $(PG_CONFIG) --pgxs)
VERSION := $(shell $(PG_CONFIG) --version)

MODULE_big = pg_cld2
OBJS = pg_cld2.o

INCLUDE_DIRS = -I$(INCLUDEDIR_SERVER) -I/usr/include/libxml2 -I/usr/include/cld2

CXX = g++
CXXFLAGS = -Wall -Wextra -Werror

pg_cld2.o: pg_cld2.c
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -c -o $@ $<

all: $(OBJS)
	$(MAKE) -C $(PGXS) all

install:
	$(MAKE) -C $(PGXS) install

clean:
	$(MAKE) -C $(PGXS) clean
	rm -f $(OBJS)

EXTRA_CLEAN = $(OBJS)

include $(PGXS)

