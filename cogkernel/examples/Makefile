# Makefile for Cognitive Services Examples
# 
# These examples demonstrate integration of OpenCog cognitive
# services with Hurd components.

CC = gcc
CFLAGS = -Wall -Wextra -g -O2 -I..
LDFLAGS = -L..
LIBS = -lpthread

# Example programs
EXAMPLES = simple-cognitive-server

# Build targets
all: $(EXAMPLES)

simple-cognitive-server: simple-cognitive-server.c ../hurd-atomspace-bridge-stub.o
	$(CC) $(CFLAGS) -o $@ $< ../hurd-atomspace-bridge-stub.o $(LIBS)

# Build stub version of bridge for examples
../hurd-atomspace-bridge-stub.o: ../hurd-atomspace-bridge-stub.c
	$(MAKE) -C .. hurd-atomspace-bridge-stub.o

# Clean
clean:
	rm -f $(EXAMPLES) *.o

# Install (not typically needed for examples)
install:
	@echo "Examples are not installed. Run them from the build directory."

.PHONY: all clean install
