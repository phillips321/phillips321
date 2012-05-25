CC=gcc
CFLAGS=-O2 -pipe
VERSION=0.8.1
BINDIR=/usr/local/bin/
DIR=onesixtyone-$(VERSION)
DISTFILES=ChangeLog INSTALL Makefile README dict.txt onesixtyone.c COPYING

all: onesixtyone

onesixtyone: onesixtyone.c
	$(CC) $(CFLAGS) -o onesixtyone onesixtyone.c

solaris: onesixtyone.c
	$(CC) $(CFLAGS) -o onesixtyone onesixtyone.c -lsocket -lnsl

install:
	install -m 0755 -o root -g 0 onesixtyone $(BINDIR)

clean:
	rm -rf onesixtyone

dist:
	rm -rf $(DIR)
	mkdir $(DIR)
	cp $(DISTFILES) $(DIR)
	tar --owner root --group 0 -cz -f $(DIR).tar.gz $(DIR)
