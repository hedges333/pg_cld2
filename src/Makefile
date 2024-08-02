PG_CONFIG = pg_config
PG_INCLUDEDIR_SERVER := $(shell $(PG_CONFIG) --includedir-server)
PG_CPPFLAGS := $(shell $(PG_CONFIG) --cppflags)
PG_PKGLIBDIR := $(shell $(PG_CONFIG) --pkglibdir)
PGXS := $(shell $(PG_CONFIG) --pgxs)
LIBDIR := $(shell $(PG_CONFIG) --libdir)

MODULE_big = pg_cld2
OBJS = pg_cld2.o
SOB  = pg_cld2.so

INCLUDE_DIRS = -I$(PG_INCLUDEDIR_SERVER)

CXX = g++
CXXFLAGS = -Wall -Wextra -Werror $(PG_CPPFLAGS)
SHLIB_LINK += -L$(LIBDIR) -L$(PG_PKGLIBDIR) -lcld2

include $(PGXS)

%.bc: %.cpp
	$(COMPILE.cxx.bc) -o $@ $<

%.o: %.c
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -c -o $@ $< $(SHLIB_LINK)

$(MODULE_big).so: $(OBJS)
	$(CXX) $(CXXFLAGS) $(INCLUDE_DIRS) -shared -o $@ $^ $(SHLIB_LINK)

all: $(MODULE_big).so

EXTRA_CLEAN = $(OBJS) $(MODULE_big).so

