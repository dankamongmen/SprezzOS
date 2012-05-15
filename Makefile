.DELETE_ON_ERROR:
.PHONY: all test clean cleanchroot clobber

CHROOT:=unstable
DBUILDOPS:=-j8 -k9978711C
DI:=debian-installer-20120509
DIBUILD:=$(CHROOT)/d-i/installer/build

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=$(shell pwd)/profiles/SprezzOS.conf
CONFIN:=$(shell pwd)/SprezzOS.conf.in
BUILDIN:=innerbuild

WORLD:=$(shell pwd)/world

PMZFS:=$(WORLD)/partman-zfs_19_all.udeb
ZMOD:=$(CHROOT)/zfs-modules_0.6.0-1_amd64.deb
ZFS:=$(CHROOT)/zfs_0.6.0-1_amd64.deb

SMOD:=$(CHROOT)/spl-modules_0.6.0-1_amd64.deb
SPL:=$(CHROOT)/spl_0.6.0-1_amd64.deb

FREETYPE:=freetype-2.4.9
LFT:=$(WORLD)/libfreetype6-udeb_2.4.9-1.1_amd64.udeb

PROFILE:=profiles/SprezzOS.packages
IMG:=images/debian-unstable-amd64-CD-1.iso
TESTDISK:=kvmdisk.img
DIIMG:=dest/netboot/mini.iso
CPDIIMG:=tmp/mirror/dists/sid/main/installer-amd64/current/images/netboot
DIDEB:=$(shell pwd)/unstable/$(DI)_amd64.deb

DEBS:=$(DIDEB) $(SPL) $(ZFS)

all: $(IMG)

test: $(TESTDISK) all
	kvm -cdrom $(IMG) -hda $< -boot d -m 4096

$(TESTDISK):
	qemu-img create $@ 40G

$(IMG): $(CONF) $(PROFILE) $(ZFS) $(SPL) $(PMZFS) $(CPDIIMG)
	build-simple-cdd --profiles SprezzOS --auto-profiles SprezzOS \
	 --dist sid --local-packages $(ZFS),$(SPL),$(ZMOD),$(SMOD),$(DIDEB)

$(CPDIIMG): $(DIIMG)
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp -r $(wildcard dest/*) $(@D)

$(PMZFS): $(WORLD)/partman-zfs/debian/rules
	cd $(<D)/.. && dpkg-buildpackage $(DBUILDOPS)

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( cat $^ && echo custom_installer=\"$(shell pwd)/dest\" ) > $@

TARGUDEBS:=$(DIBUILD)/localudebs/partman-zfs_19_all.udeb

$(DEBS) $(TARGUDEBS) $(DIIMG): $(CHROOT)/$(BUILDIN)
	sudo chroot $(CHROOT) /$(BUILDIN)

$(DIBUILD)/localudebs/%.udeb: $(WORLD)/%.udeb $(CHROOT)/$(BUILDIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp $< $@

packages.tgz: update
	./$< $@

$(CHROOT)/linux-stable:
	cd $(@D) && git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git

$(LFT):
	cd $(WORLD)/$(FREETYPE) && dpkg-buildpackage $(DBUILDOPS)

$(CHROOT)/$(BUILDIN): $(BUILDIN) build $(LFT) packages.tgz
	@! [ -e $(@D) ] || { echo "$(@D) exists. Remove it with 'make cleanchroot'." >&2 ; exit 1 ; }
	./build $(@D) $(LFT)
	cp $(BUILDIN) $@

cleanchroot:
	sudo umount $(CHROOT)/proc $(CHROOT)/sys || true
	sudo rm -rf $(CHROOT)

clean: cleanchroot
	rm -rf tmp $(TESTDISK) images $(CONF) $(PMZFS)
	rm -f $(wildcard *deb) $(wildcard zfs/*deb) $(wildcard zfs/*rpm)
	-cd $(WORLD)/partman-zfs && debian/rules clean
	-cd $(WORLD)/$(FREETYPE) && debian/rules clean

clobber: clean
	rm -f packages.tgz
