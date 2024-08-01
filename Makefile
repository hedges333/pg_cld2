# Makefile

EXTENSION = pg_cld2
EXTVERSION = 1.0.0
DISTVERSION = $(EXTVERSION)

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

DATA = $(wildcard $(SQLDIR)/*.sql)
DOCS = README.md
MODULES = $(patsubst %.c,%,$(wildcard src/*.c))

# Test settings
TESTS = $(wildcard test/in/*.sql)

REGRESS = $(notdir $(basename $(wildcard test/in/*.sql)))

PG_REGRESS = pg_regress
PG_REGRESS_OPTS = --inputdir=test/in --outputdir=test/out --expectfile=test/expected

installcheck: all
	$(PG_REGRESS) $(REGRESS)

EXTRA_CLEAN = $(wildcard test/out/*.out)

# Build and clean rules
all:
	$(MAKE) -C $(SRCDIR)

# Regression tests
# test: install
# @echo "Running regression tests..."
# $(pg_regress_installcheck) --inputdir=$(TESTDIR)/in --outputdir=$(TESTDIR)/out --expecteddir=$(TESTDIR)/expected

# Clean up build files
clean:
	$(MAKE) -C $(SRCDIR) clean
	rm -f $(SRCDIR)/*.o $(SRCDIR)/*.so

.PHONY: all build install uninstall clean test installcheck

