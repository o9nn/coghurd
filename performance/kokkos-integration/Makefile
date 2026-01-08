#
# Makefile for Kokkos Integration Module
# Part of GNU Hurd Cognitive Architecture - Performance Framework
#

dir := performance/kokkos-integration
makemode := misc

SRCS = kokkos-hurd-bridge.cc kokkos-memory-space.cc kokkos-demo.cc skz-kokkos-compatibility.cc skz-bridge-stub.c
OBJS = $(SRCS:.cc=.o)
OBJS := $(OBJS:.c=.o)
target = kokkos-hurd-demo
compatibility_target = skz-compatibility-test

# Include main build configuration  
include ../../Makeconf

# Override the GNU Hurd automatic dependency system for this module
# We handle dependencies manually to avoid Hurd library requirements
CXXFLAGS = $(CFLAGS) -std=c++14

# Kokkos-specific configuration
ifdef HAVE_KOKKOS
KOKKOS_CXXFLAGS = $(kokkos_CFLAGS)
KOKKOS_LIBS = $(kokkos_LIBS)
CPPFLAGS += -DHAVE_KOKKOS=1 $(KOKKOS_CXXFLAGS)
LDLIBS += $(KOKKOS_LIBS)
else
# Fallback when Kokkos is not available
CPPFLAGS += -DHAVE_KOKKOS=0
endif

# Manual build rules to avoid Hurd library dependencies
all: $(target) $(compatibility_target)

$(target): kokkos-hurd-bridge.o kokkos-memory-space.o kokkos-demo.o
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(compatibility_target): skz-kokkos-compatibility.o skz-bridge-stub.o kokkos-hurd-bridge.o kokkos-memory-space.o
	$(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

# C++ compilation rule
%.o: %.cc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# C compilation rule  
%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

clean:
	$(RM) $(OBJS) $(target) $(compatibility_target)

.PHONY: demo test compatibility all-targets clean

# Demonstration target
demo: $(target)
	@echo "🧠 === Running Kokkos-Hurd Integration Demo === 🧠"
	./$(target) --demo

# Test target  
test: $(target)
	@echo "⚡ === Testing Kokkos Parallel Computing Integration === ⚡"
	./$(target) --test

# SKZ compatibility verification
compatibility: $(compatibility_target)
	@echo "🔍 === Testing SKZ Framework Compatibility === 🔍"
	./$(compatibility_target)