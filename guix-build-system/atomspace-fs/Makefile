# Makefile for Atomspace Filesystem Operations
# Part of Phase 3: Build System Orchestration
# GNU Hurd - SKZ Integration

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -O2 -g -std=c99
CPPFLAGS = -I../../include -I../../libnetfs -I../../libports -I../../libiohelp
LDFLAGS = -L../../libnetfs -L../../libports -L../../libiohelp
LIBS = -lnetfs -lports -liohelp -lhurdbugaddr -lshouldbeinlibc

# Directories
SRCDIR = .
BUILDDIR = ../../build/atomspace-fs
INSTALLDIR = ../../install/atomspace-fs

# Source files
C_SOURCES = atomspace-fs-bindings.c
SCHEME_SOURCES = partition.scm implementation.scm test.scm
HEADERS = atomspace-fs-bindings.h

# Object files
OBJECTS = $(C_SOURCES:%.c=$(BUILDDIR)/%.o)

# Targets
TARGET = $(BUILDDIR)/libatomspace-fs.a
SHARED_TARGET = $(BUILDDIR)/libatomspace-fs.so

# Default target
all: $(TARGET) $(SHARED_TARGET) install-scheme

# Create build directory
$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# Create install directory
$(INSTALLDIR):
	mkdir -p $(INSTALLDIR)

# Compile C source files
$(BUILDDIR)/%.o: $(SRCDIR)/%.c $(HEADERS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

# Create static library
$(TARGET): $(OBJECTS) | $(BUILDDIR)
	ar rcs $@ $(OBJECTS)
	ranlib $@

# Create shared library
$(SHARED_TARGET): $(OBJECTS) | $(BUILDDIR)
	$(CC) -shared -o $@ $(OBJECTS) $(LDFLAGS) $(LIBS)

# Install Scheme modules
install-scheme: $(SCHEME_SOURCES) | $(INSTALLDIR)
	cp $(SCHEME_SOURCES) $(INSTALLDIR)/
	@echo "Scheme modules installed to $(INSTALLDIR)"

# Install everything
install: $(TARGET) $(SHARED_TARGET) install-scheme | $(INSTALLDIR)
	cp $(TARGET) $(INSTALLDIR)/
	cp $(SHARED_TARGET) $(INSTALLDIR)/
	cp $(HEADERS) $(INSTALLDIR)/
	@echo "Atomspace filesystem components installed to $(INSTALLDIR)"

# Test targets
test: $(TARGET) install-scheme
	@echo "Testing atomspace filesystem operations..."
	@echo "Note: Guile integration tests require Guile runtime"
	$(CC) $(CFLAGS) $(CPPFLAGS) -DDEBUG -DTEST_MAIN -o $(BUILDDIR)/test-atomspace-fs \
		$(C_SOURCES) $(LDFLAGS) $(LIBS)
	$(BUILDDIR)/test-atomspace-fs

# Clean build artifacts
clean:
	rm -rf $(BUILDDIR)
	rm -rf $(INSTALLDIR)

# Clean everything
distclean: clean
	rm -f *~

# Debug build
debug: CFLAGS += -DDEBUG -g3
debug: $(TARGET) $(SHARED_TARGET)

# Lint code
lint:
	@echo "Linting C code..."
	@if command -v cppcheck >/dev/null 2>&1; then \
		cppcheck --enable=all --std=c99 $(C_SOURCES); \
	else \
		echo "cppcheck not available, skipping lint"; \
	fi

# Format code
format:
	@echo "Formatting C code..."
	@if command -v indent >/dev/null 2>&1; then \
		indent -gnu $(C_SOURCES) $(HEADERS); \
	else \
		echo "indent not available, skipping format"; \
	fi

# Documentation
doc:
	@echo "Generating documentation..."
	@if command -v doxygen >/dev/null 2>&1; then \
		doxygen Doxyfile; \
	else \
		echo "doxygen not available, skipping documentation"; \
	fi

# Analyze dependencies
deps:
	@echo "Analyzing dependencies..."
	$(CC) $(CPPFLAGS) -MM $(C_SOURCES)

# Show configuration
config:
	@echo "=== Atomspace Filesystem Build Configuration ==="
	@echo "CC: $(CC)"
	@echo "CFLAGS: $(CFLAGS)"
	@echo "CPPFLAGS: $(CPPFLAGS)"
	@echo "LDFLAGS: $(LDFLAGS)"
	@echo "LIBS: $(LIBS)"
	@echo "BUILD DIR: $(BUILDDIR)"
	@echo "INSTALL DIR: $(INSTALLDIR)"
	@echo "==============================================="

# Performance test
perf-test: $(TARGET)
	@echo "Running performance tests..."
	$(CC) $(CFLAGS) $(CPPFLAGS) -DPERF_TEST -o $(BUILDDIR)/perf-test \
		$(C_SOURCES) $(LDFLAGS) $(LIBS)
	$(BUILDDIR)/perf-test

# Integration test with Hurd
hurd-test: $(TARGET)
	@echo "Testing Hurd integration..."
	@echo "Note: This requires proper Hurd environment"
	$(CC) $(CFLAGS) $(CPPFLAGS) -DHURD_TEST -o $(BUILDDIR)/hurd-test \
		$(C_SOURCES) $(LDFLAGS) $(LIBS)
	@echo "Hurd integration test binary created: $(BUILDDIR)/hurd-test"

# Benchmark
benchmark: $(TARGET)
	@echo "Running benchmarks..."
	$(CC) $(CFLAGS) $(CPPFLAGS) -DBENCHMARK -O3 -o $(BUILDDIR)/benchmark \
		$(C_SOURCES) $(LDFLAGS) $(LIBS)
	$(BUILDDIR)/benchmark

# Memory check
memcheck: $(TARGET)
	@echo "Running memory checks..."
	@if command -v valgrind >/dev/null 2>&1; then \
		$(CC) $(CFLAGS) $(CPPFLAGS) -DDEBUG -g -o $(BUILDDIR)/memcheck-test \
			$(C_SOURCES) $(LDFLAGS) $(LIBS); \
		valgrind --leak-check=full --show-leak-kinds=all $(BUILDDIR)/memcheck-test; \
	else \
		echo "valgrind not available, skipping memory check"; \
	fi

# Static analysis
static-analysis:
	@echo "Running static analysis..."
	@if command -v clang-analyzer >/dev/null 2>&1; then \
		clang --analyze $(CPPFLAGS) $(C_SOURCES); \
	else \
		echo "clang analyzer not available, skipping static analysis"; \
	fi

# Show help
help:
	@echo "Atomspace Filesystem Makefile"
	@echo "Available targets:"
	@echo "  all           - Build all components"
	@echo "  install       - Install all components"
	@echo "  test          - Run tests"
	@echo "  clean         - Clean build artifacts"
	@echo "  distclean     - Clean everything"
	@echo "  debug         - Build with debug symbols"
	@echo "  lint          - Lint source code"
	@echo "  format        - Format source code"
	@echo "  doc           - Generate documentation"
	@echo "  deps          - Show dependencies"
	@echo "  config        - Show build configuration"
	@echo "  perf-test     - Run performance tests"
	@echo "  hurd-test     - Test Hurd integration"
	@echo "  benchmark     - Run benchmarks"
	@echo "  memcheck      - Run memory checks"
	@echo "  static-analysis - Run static analysis"
	@echo "  help          - Show this help"

# Phony targets
.PHONY: all install install-scheme test clean distclean debug lint format doc deps config help
.PHONY: perf-test hurd-test benchmark memcheck static-analysis

# Default make target
.DEFAULT_GOAL := all

# Make directory creation order-only dependencies
$(OBJECTS): | $(BUILDDIR)