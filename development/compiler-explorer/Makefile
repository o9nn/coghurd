# HurdCog Compiler Explorer JIT Infrastructure Makefile
# Part of Phase 2: Microkernel Integration - SKZ Framework

# Compiler and flags
CC = gcc
CFLAGS = -std=c99 -Wall -Wextra -O2 -fPIC
INCLUDES = -I./src -I./include
LIBS = 

# Directories
SRCDIR = src
INCDIR = include
TESTDIR = tests
BUILDDIR = build

# Source files
SOURCES = $(SRCDIR)/jit_compiler.c
OBJECTS = $(BUILDDIR)/jit_compiler.o
HEADERS = $(SRCDIR)/jit_compiler.h $(SRCDIR)/jit_config.h

# Library target
LIBRARY = $(BUILDDIR)/libhurdcog_jit.a
SHARED_LIB = $(BUILDDIR)/libhurdcog_jit.so

# Test files
TEST_SOURCES = $(TESTDIR)/test_jit.c
TEST_OBJECTS = $(BUILDDIR)/test_jit.o  
TEST_BINARY = $(BUILDDIR)/test_jit

# Default target
.PHONY: all clean test install

all: $(LIBRARY) $(SHARED_LIB)

# Create build directory
$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# Compile object files
$(BUILDDIR)/%.o: $(SRCDIR)/%.c $(HEADERS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Create static library
$(LIBRARY): $(OBJECTS)
	ar rcs $@ $^

# Create shared library  
$(SHARED_LIB): $(OBJECTS)
	$(CC) -shared -o $@ $^ $(LIBS)

# Test compilation
$(BUILDDIR)/test_jit.o: $(TESTDIR)/test_jit.c $(HEADERS) | $(BUILDDIR)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(TEST_BINARY): $(TEST_OBJECTS) $(LIBRARY)
	$(CC) -o $@ $^ $(LIBS)

# Test target
test: $(TEST_BINARY)
	@echo "Running JIT infrastructure tests..."
	./$(TEST_BINARY)

# Install target (minimal implementation)
install: $(LIBRARY) $(SHARED_LIB)
	@echo "Installing JIT library..."
	@mkdir -p $(PREFIX)/lib $(PREFIX)/include/hurdcog
	cp $(LIBRARY) $(SHARED_LIB) $(PREFIX)/lib/
	cp $(SRCDIR)/jit_compiler.h $(PREFIX)/include/hurdcog/

# Clean target
clean:
	rm -rf $(BUILDDIR)

# Development targets
demo: $(TEST_BINARY)
	@echo "=== HurdCog JIT Infrastructure Demo ==="
	./$(TEST_BINARY) --demo

# Help target
help:
	@echo "HurdCog Compiler Explorer JIT Infrastructure"
	@echo "============================================="
	@echo "Targets:"
	@echo "  all       - Build static and shared libraries"
	@echo "  test      - Build and run tests"  
	@echo "  demo      - Run demonstration"
	@echo "  install   - Install libraries and headers"
	@echo "  clean     - Remove build artifacts"
	@echo ""
	@echo "Environment Variables:"
	@echo "  CC        - C compiler (default: gcc)"
	@echo "  CFLAGS    - Additional compiler flags"
	@echo "  PREFIX    - Install prefix (default: /usr/local)"

# Include dependency files if they exist
-include $(BUILDDIR)/*.d

# Generate dependencies  
$(BUILDDIR)/%.d: $(SRCDIR)/%.c | $(BUILDDIR)
	@$(CC) $(CFLAGS) $(INCLUDES) -MM -MF $@ -MT '$(BUILDDIR)/$*.o $@' $<

# Pattern rule for dependencies
deps: $(SOURCES:$(SRCDIR)/%.c=$(BUILDDIR)/%.d)