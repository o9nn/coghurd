#
# Makefile for Performance Optimization Module
# Part of GNU Hurd Cognitive Architecture - Performance Framework
# Phase 5: Month 17 Implementation
#

# Use standalone build configuration to avoid Hurd Makeconf issues
CXX = g++
CC = gcc
CXXFLAGS = -std=c++14 -pthread -Wall -g -O2
CFLAGS = -Wall -g -O2
CPPFLAGS = -I. -I.. -I../include -DHAVE_KOKKOS=0

# Source files for performance optimization
SRCS = performance-optimizer-simple.cc performance-test.cc
OBJS = $(SRCS:.cc=.o)

# Include Kokkos integration sources
KOKKOS_SRCS = kokkos-integration/kokkos-hurd-bridge.cc \
              kokkos-integration/kokkos-memory-space.cc \
              kokkos-integration/kokkos-demo.cc \
              kokkos-integration/skz-kokkos-compatibility.cc \
              kokkos-integration/skz-bridge-stub.c

KOKKOS_OBJS = $(KOKKOS_SRCS:.cc=.o)
KOKKOS_OBJS := $(KOKKOS_OBJS:.c=.o)

ALL_OBJS = $(OBJS) $(KOKKOS_OBJS)

# Build targets
performance_target = performance-test
kokkos_target = kokkos-hurd-demo
compatibility_target = skz-compatibility-test
targets = $(performance_target) $(kokkos_target) $(compatibility_target)

# Manual build rules
all: $(targets)

# Main performance test target
$(performance_target): performance-optimizer-simple.o performance-test.o kokkos-integration/kokkos-hurd-bridge.o kokkos-integration/kokkos-memory-space.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDLIBS)

# Kokkos demo target
$(kokkos_target): kokkos-integration/kokkos-hurd-bridge.o kokkos-integration/kokkos-memory-space.o kokkos-integration/kokkos-demo.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDLIBS)

# SKZ compatibility target
$(compatibility_target): kokkos-integration/skz-kokkos-compatibility.o kokkos-integration/skz-bridge-stub.o kokkos-integration/kokkos-hurd-bridge.o kokkos-integration/kokkos-memory-space.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDLIBS)

# C++ compilation rule
%.o: %.cc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

# C compilation rule for kokkos-integration
kokkos-integration/%.o: kokkos-integration/%.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# C++ compilation rule for kokkos-integration
kokkos-integration/%.o: kokkos-integration/%.cc
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

clean:
	$(RM) $(ALL_OBJS) $(targets)

.PHONY: test demo benchmark skz-test all-targets clean

# Main performance test target
test: $(performance_target)
	@echo "🚀 === Running Performance Optimization Test Suite === 🚀"
	./$(performance_target) --test

# Performance benchmark
benchmark: $(performance_target)
	@echo "⚡ === Running Performance Benchmark === ⚡"
	./$(performance_target) --benchmark

# SKZ integration test
skz-test: $(performance_target)
	@echo "🔗 === Testing SKZ Framework Integration === 🔗"
	./$(performance_target) --skz

# Kokkos demonstration target
demo: $(kokkos_target)
	@echo "🧠 === Running Kokkos-Hurd Integration Demo === 🧠"
	./$(kokkos_target) --demo

# SKZ compatibility verification
compatibility: $(compatibility_target)
	@echo "🔍 === Testing SKZ Framework Compatibility === 🔍"
	./$(compatibility_target)

# Run all tests and demonstrations
all-targets: test demo benchmark skz-test compatibility
	@echo "🎉 === All Performance Tests Completed === 🎉"

# Development testing - run basic functionality
dev-test: $(performance_target)
	@echo "🧪 === Development Test === 🧪"
	./$(performance_target) --benchmark