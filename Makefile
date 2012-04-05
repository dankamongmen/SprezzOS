.PHONY: all test update clean clobber nukefromorbit spl zfs

DI:=debian-installer
DIBUILD:=$(DI)/installer/build
DIIMG:=some.iso

CONF:=$(shell pwd)/cdd.conf
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

$(IMG): $(CONF) $(PROFILE) zfs/zfs_0.6.0-1_amd64.deb
	simple-cdd --conf $< --dist sid --profiles-udeb-dist sid \
		--profiles SprezzOS --auto-profiles SprezzOS

zfs/zfs_0.6.0-1_amd64.deb: spl_0.6.0-rc8-1_amd64.deb
	cd zfs && ./configure && make deb

spl_0.6.0-rc8-1_amd64.deb:
	cd spl && sudo debian/rules binary

$(DIIMG): $(DIBUILD)/$(SLIST) $(DIBUILD)/config/common
	cd $(DIBUILD) && make build_cdrom_isolinux

CANARY:=$(DI)/packages/finish-install/.git/config

$(DIBUILD)/config/common: common $(CANARY)
	cat $< > $@

$(DIBUILD)/$(SLIST): $(SLIST) $(CANARY)
	cat $< > $@

update: $(DI)/.mrconfig
	cd $(DI) && svn up && mr update

$(CANARY):
	[ -d $(DI) ] || svn co svn://svn.debian.org/svn/d-i/trunk $(DI)
	cd $(DI) && scripts/git-setup && mr -p checkout

clean:
	rm -rf tmp $(TESTDISK) images
	-cd zfs && make clean
	-cd spl && make clean

clobber:
	cd $(DI) && svn-clean -f

nukefromorbit:
	rm -rf $(DI)
