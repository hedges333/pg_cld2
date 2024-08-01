PG_CONFIG = pg_config
PG_INCLUDEDIR_SERVER := $(shell $(PG_CONFIG) --includedir-server)
PGXS := $(shell $(PG_CONFIG) --pgxs)

MODULE_big = pg_cld2
OBJS = pg_cld2.o
SOBS = pg_cld2.so  # pretty much what I'm doing by now trying to make this work

INCLUDE_DIRS = -I$(PG_INCLUDEDIR_SERVER)

CXX = g++
CXXFLAGS = -Wall -Wextra -Werror

pg_cld2.o: pg_cld2.c
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -c -o $@ $<

EXTRA_CLEAN = $(OBJS) $(SOBS)

include $(PGXS)

