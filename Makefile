.PHONY: all test update clean clobber nukefromorbit spl zfs

DI:=debian-installer
DIBUILD:=$(DI)/build
DIIMG:=debian-installer_201204xy_amd64.deb

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=$(shell pwd)/cdd.conf
ZFS:=$(shell pwd)/zfs/zfs_0.6.0-1_amd64.deb
SPL:=$(shell pwd)/spl_0.6.0-rc8-1_amd64.deb

PROFILE:=profiles/SprezzOS.packages
IMG:=images/debian-unstable-amd64-CD-1.iso
TESTDISK:=kvmdisk.img
SLIST:=sources.list.udeb.local

# don't yet use $(DIIMG), our custom build of debian-installer
all: $(IMG)

test: $(TESTDISK) all
	kvm -cdrom $(IMG) -hda $<

$(TESTDISK):
	kvm-img create $@ 40G

 #$(DIIMG)
$(IMG): $(CONF) $(PROFILE) $(ZFS)
	simple-cdd --conf $< --dist sid --profiles-udeb-dist sid \
		--profiles SprezzOS --auto-profiles SprezzOS \
		--local-packages $(ZFS)

zfs: $(ZFS)

$(ZFS): $(SPL)
	cd zfs && ./configure && make deb

$(SPL): spl/Makefile
	cd spl && sudo debian/rules binary

spl/Makefile: spl/configure
	cd spl && ./configure

$(DIIMG): $(DIBUILD)/$(SLIST) $(DIBUILD)/config/common
	cd $(DI) && fakeroot debian/rules binary

CANARY:=$(DI)/packages/finish-install/.git/config

$(DIBUILD)/config/common: common $(CANARY)
	cat $< > $@

$(DIBUILD)/$(SLIST): $(SLIST) $(CANARY)
	cat $< > $@

update: $(DI)/.mrconfig
	git submodule update
	cd $(DI) && mr update

$(CANARY):
	[ -d $(DI) ] || { git submodule init && git submodule update ; }

clean:
	rm -rf tmp $(TESTDISK) images
	rm -f $(wildcard *deb) $(wildcard zfs/*deb) $(wildcard zfs/*rpm)
	-cd zfs && make maintainer-clean || true
	-cd spl && make maintainer-clean || true

clobber:
	cd $(DIBUILD) && make reallyclean

nukefromorbit:
	rm -rf $(DI)
