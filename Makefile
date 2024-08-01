# Makefile

EXTENSION = pg_cld2
EXTVERSION = 1.0.0
DISTVERSION = $(EXTVERSION)
PGFILEDESC = "pg_cld2 - CLD2 language detection"

# PG_CONFIG and PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
PG_CPPFLAGS = $(shell $(PG_CONFIG) --cppflags)
PG_LIBS = $(shell $(PG_CONFIG) --libs)
PG_INCLUDEDIR_SERVER = $(shell $(PG_CONFIG) --includedir-server)
include $(PGXS)

# Directories
SQLDIR = sql
TESTDIR = test
SRCDIR = src

# Files
EXTENSION_SQL = $(SQLDIR)/pg_cld2--$(EXTVERSION).sql
EXTENSION_UNINSTALL = $(SQLDIR)/uninstall_pg_cld2.sql
EXTENSION_UNPACKAGED = $(SQLDIR)/pg_cld2--unpackaged--$(EXTVERSION).sql

DATA = $(wildcard $(SQLDIR)/*.sql) pg_cld2.control
DATA_FILENAMES = $(notdir $(wildcard $(SQLDIR)/*.sql)) pg_cld2.control
DOCS = README.md
MODULE_big = pg_cld2
OBJS = $(SRCDIR)/pg_cld2.o

# Test settings
TESTS = $(wildcard test/in/*.sql)

REGRESS = $(notdir $(wildcard test/in/*.sql))

REGRESS = pg_regress
REGRESS_OPTS = --inputdir=test/in --outputdir=test/out

installcheck: all
	$(PG_REGRESS) $(REGRESS) $(REGRESS_OPTS)

EXTRA_CLEAN = $(wildcard test/out/*.out) $(MODULE_BIG.so)

install: all installdirs install-data install-lib

all:
	$(MAKE) -C $(SRCDIR)
	$(MAKE) -C $(SRCDIR) $(MODULE_big).so

install-data: installdirs
	$(INSTALL_DATA) $(DATA) '$(DESTDIR)$(datadir)/extension/'

install-lib: installdirs
	$(INSTALL_SHLIB) '$(SRCDIR)/$(MODULE_big).so' '$(DESTDIR)$(libdir)/'

# Regression tests

# Clean up build files
clean:
	$(MAKE) -C $(SRCDIR) clean
	rm -f $(SRCDIR)/*.o $(SRCDIR)/*.so

uninstall:
	@echo $(DATA_FILENAMES)
	rm -fv '$(DESTDIR)$(libdir)/$(MODULE_big).so'
	$(foreach filename, $(DATA_FILENAMES), rm -fv '$(DESTDIR)$(datadir)/extension/$(filename)';)


.PHONY: all install uninstall clean test installcheck

