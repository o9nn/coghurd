# Makefile for Cognitive Kernels (ggml)
# Neural-Symbolic Synthesis via Custom ggml Kernels

CC = gcc
CFLAGS = -Wall -Wextra -O2 -fPIC -std=c99
LDFLAGS = -lm -lpthread
INCLUDE = -I.

# Source files
SOURCES = cognitive_tensor_ops.c \
          symbolic_reasoning.c \
          attention_kernels.c \
          hypergraph_ops.c \
          atomspace_bridge.c \
          hurd_cognitive_api.c

# Object files
OBJECTS = $(SOURCES:.c=.o)

# Header files
HEADERS = cognitive_kernels.h \
          tensor_signatures.h \
          atomspace_bridge.h \
          hurd_cognitive_api.h

# Library
LIBRARY = libcognitive_kernels.a
SHARED_LIBRARY = libcognitive_kernels.so

# Test executable
TEST_EXEC = test_cognitive_kernels

# Benchmark executable
BENCHMARK_EXEC = benchmark_cognitive_kernels

# Default target
all: $(LIBRARY) $(SHARED_LIBRARY) $(TEST_EXEC) $(BENCHMARK_EXEC)

# Build static library
$(LIBRARY): $(OBJECTS)
	@echo "Creating static library: $@"
	ar rcs $@ $^

# Build shared library
$(SHARED_LIBRARY): $(OBJECTS)
	@echo "Creating shared library: $@"
	$(CC) -shared -o $@ $^ $(LDFLAGS)

# Build test executable
$(TEST_EXEC): test_cognitive_kernels.o $(OBJECTS)
	@echo "Building test executable: $@"
	$(CC) -o $@ $^ $(LDFLAGS)

# Build benchmark executable
$(BENCHMARK_EXEC): benchmark_cognitive_kernels.o $(OBJECTS)
	@echo "Building benchmark executable: $@"
	$(CC) -o $@ $^ $(LDFLAGS)

# Compile source files
%.o: %.c $(HEADERS)
	@echo "Compiling: $<"
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

# Run tests
test: $(TEST_EXEC)
	@echo ""
	@echo "Running cognitive kernels tests..."
	@echo ""
	./$(TEST_EXEC)

# Performance benchmark
benchmark: $(BENCHMARK_EXEC)
	@echo ""
	@echo "Running performance benchmarks..."
	@echo ""
	./$(BENCHMARK_EXEC)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(OBJECTS) test_cognitive_kernels.o benchmark_cognitive_kernels.o
	rm -f $(LIBRARY) $(SHARED_LIBRARY)
	rm -f $(TEST_EXEC) $(BENCHMARK_EXEC)

# Install headers and library
install: $(LIBRARY) $(SHARED_LIBRARY)
	@echo "Installing cognitive kernels..."
	install -d $(DESTDIR)/usr/local/include/cognitive_kernels
	install -m 644 $(HEADERS) $(DESTDIR)/usr/local/include/cognitive_kernels/
	install -d $(DESTDIR)/usr/local/lib
	install -m 644 $(LIBRARY) $(DESTDIR)/usr/local/lib/
	install -m 755 $(SHARED_LIBRARY) $(DESTDIR)/usr/local/lib/

# Uninstall
uninstall:
	@echo "Uninstalling cognitive kernels..."
	rm -rf $(DESTDIR)/usr/local/include/cognitive_kernels
	rm -f $(DESTDIR)/usr/local/lib/$(LIBRARY)
	rm -f $(DESTDIR)/usr/local/lib/$(SHARED_LIBRARY)

# Generate documentation
docs:
	@echo "Generating documentation..."
	@if command -v doxygen >/dev/null 2>&1; then \
		doxygen Doxyfile; \
	else \
		echo "Doxygen not found. Please install doxygen to generate documentation."; \
	fi

# Check for memory leaks with valgrind
memcheck: $(TEST_EXEC)
	@echo "Running memory leak check..."
	@if command -v valgrind >/dev/null 2>&1; then \
		valgrind --leak-check=full --show-leak-kinds=all ./$(TEST_EXEC); \
	else \
		echo "Valgrind not found. Please install valgrind for memory checking."; \
	fi

# Code coverage
coverage: CFLAGS += -fprofile-arcs -ftest-coverage
coverage: LDFLAGS += -lgcov --coverage
coverage: clean $(TEST_EXEC)
	@echo "Running tests with coverage..."
	./$(TEST_EXEC)
	@echo "Generating coverage report..."
	@if command -v gcov >/dev/null 2>&1; then \
		gcov $(SOURCES); \
	else \
		echo "gcov not found. Please install gcov for coverage analysis."; \
	fi

# Static analysis
analyze:
	@echo "Running static analysis..."
	@if command -v cppcheck >/dev/null 2>&1; then \
		cppcheck --enable=all --inconclusive --std=c99 $(SOURCES); \
	else \
		echo "cppcheck not found. Please install cppcheck for static analysis."; \
	fi

# Help
help:
	@echo "Cognitive Kernels Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all         - Build libraries and tests (default)"
	@echo "  test        - Run test suite"
	@echo "  benchmark   - Run performance benchmarks"
	@echo "  clean       - Remove build artifacts"
	@echo "  install     - Install libraries and headers"
	@echo "  uninstall   - Remove installed files"
	@echo "  docs        - Generate documentation"
	@echo "  memcheck    - Check for memory leaks"
	@echo "  coverage    - Generate code coverage report"
	@echo "  analyze     - Run static analysis"
	@echo "  help        - Show this help message"

.PHONY: all test benchmark clean install uninstall docs memcheck coverage analyze help
