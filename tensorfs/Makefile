# TensorFS Makefile
# Multi-Entity & Multi-Scale Network-Aware Tensor-Enhanced Hurd FileSystem
#
# Copyright (C) 2025 GNU Hurd Project
# License: GPL-3.0-or-later

CC = gcc
CFLAGS = -Wall -Wextra -O2 -fPIC -std=gnu11
LDFLAGS = -lm -lpthread

# Hurd-specific flags (uncomment when building on GNU Hurd)
# CFLAGS += -I/usr/include/hurd
# LDFLAGS += -lhurd-slab -lports -lfshelp -ldiskfs

# Source files
SRCS = tensorfs.c
OBJS = $(SRCS:.c=.o)

# Library targets
LIB_STATIC = libtensorfs.a
LIB_SHARED = libtensorfs.so

# Scheme modules (for guile integration)
SCHEME_MODULES = tensorfs.scm
GUILE_SITE_DIR ?= $(PREFIX)/share/guile/site/3.0

# Installation directories
PREFIX ?= /usr/local
LIBDIR = $(PREFIX)/lib
INCLUDEDIR = $(PREFIX)/include
BINDIR = $(PREFIX)/bin

.PHONY: all clean install uninstall test scheme-test

all: $(LIB_STATIC) $(LIB_SHARED)

$(LIB_STATIC): $(OBJS)
	ar rcs $@ $^

$(LIB_SHARED): $(OBJS)
	$(CC) -shared -o $@ $^ $(LDFLAGS)

%.o: %.c tensorfs.h
	$(CC) $(CFLAGS) -c $< -o $@

# Test program
test: tensorfs-test
	./tensorfs-test

tensorfs-test: tensorfs-test.c $(LIB_STATIC)
	$(CC) $(CFLAGS) -o $@ $< -L. -ltensorfs $(LDFLAGS)

# Scheme tests
scheme-test:
	cd .. && guile -L . -c "(use-modules (tensorfs tensorfs)) (display \"TensorFS module loaded successfully\n\")"

# Installation
install: all
	install -d $(DESTDIR)$(LIBDIR)
	install -d $(DESTDIR)$(INCLUDEDIR)/tensorfs
	install -d $(DESTDIR)$(GUILE_SITE_DIR)/tensorfs
	install -m 644 $(LIB_STATIC) $(DESTDIR)$(LIBDIR)/
	install -m 755 $(LIB_SHARED) $(DESTDIR)$(LIBDIR)/
	install -m 644 tensorfs.h $(DESTDIR)$(INCLUDEDIR)/tensorfs/
	install -m 644 $(SCHEME_MODULES) $(DESTDIR)$(GUILE_SITE_DIR)/tensorfs/

uninstall:
	rm -f $(DESTDIR)$(LIBDIR)/$(LIB_STATIC)
	rm -f $(DESTDIR)$(LIBDIR)/$(LIB_SHARED)
	rm -rf $(DESTDIR)$(INCLUDEDIR)/tensorfs
	rm -rf $(DESTDIR)$(GUILE_SITE_DIR)/tensorfs

clean:
	rm -f $(OBJS) $(LIB_STATIC) $(LIB_SHARED) tensorfs-test

# Documentation
.PHONY: docs
docs:
	@echo "TensorFS Documentation:"
	@echo "  - README.md: Overview and usage"
	@echo "  - tensorfs.h: C API reference"
	@echo "  - tensorfs.scm: Scheme API reference"
