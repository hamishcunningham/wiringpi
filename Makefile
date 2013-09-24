# Makefile for WiringPi
# This code is licenced under LGPL 3 or any later version -- see 
# ./COPYING.LESSER

# vars #######################################################################
VERSION=$(shell grep VERSION gpio/gpio.c |head -1 |sed -e 's,[^"]*",,' -e 's,",,')
P=wiringpi
D=gpio
PD=package/$(VERSION)
INSTALLED_FILES=\
  $(DESTDIR)/usr/sbin/$(D) \
#  TODO includes and .so \
  $(DESTDIR)/usr/share/man/man1/$(D).1.gz
PACKAGE_FILES=\
  $(P)_$(VERSION)*.deb \
  $(P)_$(VERSION)*.dsc \
  $(P)_$(VERSION)*.tar.gz \
  $(P)_$(VERSION)*.changes \
  $(P)_$(VERSION)*.build
PPA:=ppa:hamish-dcs/pi-gate
NOW:=$(shell date "+%Y-%m-%d-%R" |sed 's,:,,')
MAJOR_VERSION:=$(shell echo $(VERSION) |sed 's,\([0-9]*\)\..*,\1,')
MINOR_VERSION:=$(shell echo $(VERSION) |sed 's,.*\.,,')
SNAPSHOT_VERSION:=$(VERSION)+$(shell expr $(MINOR_VERSION) + 1)
SNAPSHOT:=$(SNAPSHOT_VERSION)-SNAPSHOT-$(NOW)
SNAPD:=$(PD)/snapshots/$(SNAPSHOT)

# functions ##################################################################
do-listing=\
  ls $(INSTALLED_FILES) || :

# help #######################################################################
help:
	@echo 'Makefile for WiringPi Debian Packaging                        '
	@echo '                                                              '
	@echo 'Usage:                                                        '
	@echo '   make install                   installs WiringPi           '
	@echo '   make uninstall                 removes WiringPi            '
	@echo '   make list                      list installed files        '
	@echo '   make package                   create .deb/.dcs packagings '
	@echo '   make package-upload            upload to PPA repository    '
	@echo '   make package-clean             delete tmp packaging files  '
	@echo '   make package-info              apt-cache showpkg           '
	@echo '   make package-purge             apt-get purge               '
	@echo '   make package-version           update the changelog        '
	@echo '                                                              '

# install ####################################################################
# (if DESTDIR is set we assume this is a packaging run, not an install)
install:
#	TODO call subdirs Makes
	@$(do-listing)

# uninstall ##################################################################
uninstall:
	@echo 'removing WiringPi files: '
#	TODO call subdirs Makes
	@$(do-listing)
	@echo done

# manpage ####################################################################
man: man/$(D).1
	cd man; cat $(D).1 |gzip >$(D).1.gz

# package ####################################################################
package: man package-unstable package-precise
	@echo "\nunstable:"
	@ls -lh $(PD)/unstable
	@echo "\nprecise:"
	@ls -lh $(PD)/precise
package-unstable:
	@echo 'packaging WiringPi for Debian unstable...'
	mkdir -p $(PD)/unstable
	rm -f $(PD)/unstable/*
	sed -i \
          's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1unstable,' debian/changelog
	debuild -Ipackage
	@echo ""
	cd .. && for f in $(PACKAGE_FILES); do \
          [ -f $$f ] && mv $$f $(D)/$(PD)/unstable || :; done
package-precise:
	@echo 'packaging WiringPi for Ubuntu precise...'
	mkdir -p $(PD)/precise
	rm -f $(PD)/precise/*
	sed -i 's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1precise,' debian/changelog
	debuild -S -Ipackage
	sed -i 's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1unstable,' \
          debian/changelog
	@echo ""
	cd .. && for f in $(PACKAGE_FILES); do \
          [ -f $$f ] && mv $$f $(D)/$(PD)/precise || :; done
snapshot:
	@echo "packaging WiringPi SNAPSHOT $(SNAPSHOT)..."
	mkdir -p $(SNAPD)
	rm -rf $(SNAPD)/*
	sed -i -e 's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1precise,' \
	       -e 's,^$(P) ($(VERSION),$(P) ($(SNAPSHOT_VERSION),' \
          debian/changelog
	@head -1 debian/changelog
	debuild -S -Ipackage
	sed -i -e 's,^$(P) ($(SNAPSHOT_VERSION),$(P) ($(VERSION),' \
               -e 's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1unstable,' \
          debian/changelog
	@head -1 debian/changelog
	@echo ""
	cd .. && for f in $(PACKAGE_FILES); do \
          [ -f $$f ] && mv $$f $(D)/$(SNAPD) || :; done
	@echo "\nsnapshot:"
	@ls -lhR $(SNAPD)

# package-upload #############################################################
package-upload:
	cd $(PD)/precise && dput $(PPA) \
          $(P)_$(VERSION)_source.changes
	cd $(PD)/precise && mv $(P)_$(VERSION)*.ppa.upload /tmp || :

# snapshot-upload ############################################################
# relies on lexical ordering of snapshot names to pick the latest one
# (apt also relies on this ordering)
snapshot-upload:
	cd package/$(VERSION)/snapshots; \
	LAST_SNAP=`ls -r |head -1`; \
        cd $$LAST_SNAP && \
          dput $(PPA)-snapshots $(P)*_source.changes; \
	mv $(P)_*.ppa.upload /tmp || :

# package utilities
package-info:
	apt-cache showpkg $(P)
package-purge:
	apt-get purge $(P)
package-clean:
	dh_clean
package-version:
	dch -i

# list #######################################################################
list:
	@$(do-listing)

# phonies ####################################################################
.PHONY: install uninstall package package-unstable package-precise
.PHONY: package-upload package-clean list
