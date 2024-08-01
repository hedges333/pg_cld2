PG_CONFIG = pg_config
PG_INCLUDEDIR_SERVER := $(shell $(PG_CONFIG) --includedir-server)
PGXS := $(shell $(PG_CONFIG) --pgxs)

MODULES = pg_cld2
OBJS = pg_cld2.o

INCLUDE_DIRS = -I$(PG_INCLUDEDIR_SERVER)

CXX = g++
CXXFLAGS = -Wall -Wextra -Werror

pg_cld2.o: pg_cld2.c
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -c -o $@ $<

EXTRA_CLEAN = $(OBJS)

include $(PGXS)

