# Makefile for 9pfs - 9P filesystem translator
#
# This translator provides 9P protocol file system access for GNU Hurd
# using the universal file interface abstraction

dir := 9pfs
makemode := server

target = 9pfs
SRCS = 9pfs.c node.c ops.c netfs.c

# Use Hurd libraries
HURDLIBS = netfs fshelp iohelp ports shouldbeinlibc
LDLIBS += -lpthread

# Include the 9P library
CPPFLAGS += -I../lib9p
9pfs-LDFLAGS = -L../lib9p -l9p

include ../Makeconf