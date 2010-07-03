##
## Process with automake to produce Makefile.in
##

SUBDIRS = src libicq2000 examples

EXTRA_DIST = TODO THANKS NEWS doc libicq2000.pc.in doxyfile.conf

pkgconfigdir            = $(libdir)/pkgconfig
pkgconfig_DATA          = libicq2000.pc

docs: src/*.cpp src/*.h
	doxygen doxyfile.conf
	touch docs

dist: docs

install-docs: docs
	if [ ! -d $(DESTDIR)$(docdir) ]; then \
	  mkdir -p $(DESTDIR)$(docdir) ; \
	fi; \
	cp -r $(top_srcdir)/doc/* $(DESTDIR)$(docdir)

