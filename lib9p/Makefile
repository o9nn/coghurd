# Makefile for lib9p - Plan9 9P protocol library
#
# This library implements the Plan9 9P protocol for GNU Hurd
# providing universal file interface and distributed resource access

dir := lib9p
makemode := library
libname = lib9p

SRCS = 9p-protocol.c 9p-server.c 9p-client.c 9p-auth.c 9p-namespace.c
installhdrs = 9p.h
LCLHDRS = 9p-internal.h

# Link with standard Hurd libraries and pthread
LDLIBS += -lpthread

include ../Makeconf