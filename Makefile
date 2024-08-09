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
PG_INCLUDEDIR = $(shell $(PG_CONFIG) --includedir)
PG_BINDIR = $(shell $(PG_CONFIG) --bindir)
PG_PKGLIBDIR = $(shell $(PG_CONFIG) --pkglibdir)
PG_REGRESS = $(PG_PKGLIBDIR)/pgxs/src/test/regress/pg_regress
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

# Compilation and linking flags -
# necessary for other targets managed by pgxs, not just making .o/.so
SHLIB_LINK += -L$(PG_PKGLIBDIR) -lcld2
# must be exported or it doesn't work
export SHLIB_LINK

# Test settings
REGRESS = $(notdir $(basename $(wildcard test/sql/*.sql)))
#REGRESS = tests-01

REGRESS_OPTS = --inputdir=test --outputdir=test --dbname=pg_cld2_regression --debug
BUILDDIR := $(shell pwd)
TESTDIR_ABS := $(shell pwd)/test

installcheck: all
	$(MKDIR_P) test/results
	TESTDIR_ABS=$(TESTDIR_ABS) $(PG_REGRESS) $(REGRESS) $(REGRESS_OPTS)

EXTRA_CLEAN = $(wildcard test/out/*.out) \
			  $(wildcard test/results/*) test/regression.diffs \
			  $(wildcard $(SRCDIR)/*.o) $(wildcard $(SRCDIR)/*.so) \
			  $(wildcard $(SRCDIR)/*.bc)

install: all installdirs install-data install-lib

all:
	$(MAKE) -C $(SRCDIR)
	$(MAKE) -C $(SRCDIR) $(MODULE_big).so

install-data: installdirs
	$(INSTALL_DATA) $(DATA) '$(DESTDIR)$(datadir)/extension/'

install-lib: installdirs
	$(INSTALL_SHLIB) '$(SRCDIR)/$(MODULE_big).so' '$(DESTDIR)$(pkglibdir)/'

# Regression tests

# Clean up build files
# not sure why EXTRA_CLEAN doesn't work with the default clean target

clean:
	rm -fv $(EXTRA_CLEAN)

#$(MAKE) -C $(SRCDIR) clean
#rm -fv $(SRCDIR)/*.o $(SRCDIR)/*.so
#rm -rf test/out/* test/results

uninstall:
	@echo $(DATA_FILENAMES)
	cat $(EXTENSION_UNINSTALL) | sudo -u postgres psql postgres
	rm -fv '$(DESTDIR)$(pkglibdir)/$(MODULE_big).so'
	$(foreach filename, $(DATA_FILENAMES), rm -fv '$(DESTDIR)$(datadir)/extension/$(filename)';)


.PHONY: all install uninstall clean test installcheck

