.DELETE_ON_ERROR:
.PHONY: all test clean zfs

# There's surely a better way to pass this to dpkg-buildpackage etc...FIXME
CONCURRENCY:=-j8

DI:=debian-installer-20120327
CHROOT:=unstable
DIBUILD:=$(CHROOT)/$(DI)/build

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=$(shell pwd)/profiles/SprezzOS.conf
CONFIN:=$(shell pwd)/SprezzOS.conf.in
BUILDIN:=innerbuild
UDEBS:=$(shell pwd)/udebs
PMZFS:=$(UDEBS)/partman-zfs_1-1_all.udeb

ZMOD:=$(shell pwd)/zfs/zfs-modules_0.6.0-1_amd64.deb
ZFS:=$(shell pwd)/zfs/zfs_0.6.0-1_amd64.deb

SMOD:=$(shell pwd)/spl/spl-modules_0.6.0-1_amd64.deb
SPL:=$(shell pwd)/spl/spl_0.6.0-1_amd64.deb

PROFILE:=profiles/SprezzOS.packages
IMG:=images/debian-unstable-amd64-CD-1.iso
TESTDISK:=kvmdisk.img
DIIMG:=dest/netboot/mini.iso
CPDIIMG:=tmp/mirror/dists/sid/main/installer-amd64/current/images/netboot
DIDEB:=$(shell pwd)/unstable/debian-installer_20120327_amd64.deb

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

#--profiles-udeb-dist $(UDEBS) #--extra-udeb-dist $(UDEBS)

$(PMZFS): $(UDEBS)/partman-zfs/debian/rules
	cd $(<D)/.. && dpkg-buildpackage -k9978711C -b

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( cat $^ && echo "custom_installer=$(shell pwd)/dest" ) > $@

TARGUDEBS:=$(DIBUILD)/localudebs/partman-zfs_1-1_all.udeb
TARGUDEBS+=$(DIBUILD)/localudebs/zfs_1-1_all.udeb
TARGUDEBS+=$(CHROOT)/root/udebs/partman-zfs_1-1_all.udeb
TARGUDEBS+=$(CHROOT)/root/udebs/zfs_1-1_all.udeb

$(DIIMG): $(DIBUILD)/config/common $(CHROOT)/build $(TARGUDEBS)
	sudo chroot $(CHROOT) /build

$(UDEBS)/zfs_1-1_all.udeb: zfs_1-1_all.udeb
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp $< $@

zfs_1-1_all.udeb:
	cd zfs && dpkg-buildpackage -k9978711C -b

$(CHROOT)/root/udebs/%.udeb: $(UDEBS)/%.udeb $(CHROOT)/build
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp $< $@

$(DIBUILD)/localudebs/%.udeb: $(UDEBS)/%.udeb $(CHROOT)/build
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp $< $@

$(CHROOT)/build: $(BUILDIN) common
	sudo debootstrap --include=debian-keyring,kernel-wedge,automake,autoconf,udev,vim-nox,locales --variant=buildd unstable $(@D) http://ftp.us.debian.org/debian
	sudo chroot $(@D) mount -t proc procfs /proc
	sudo chroot $(@D) dpkg-reconfigure locales
	echo "deb-src http://ftp.us.debian.org/debian/ unstable main non-free contrib" | sudo tee -a $(CHROOT)/etc/apt/sources.list
	sudo chroot $(@D) apt-get -y update
	sudo chroot $(@D) apt-get -y build-dep debian-installer
	sudo chroot $(@D) apt-get source debian-installer
	sudo chroot $(@D) umount /proc
	sudo chown -R $(shell whoami) $(@D)
	sudo chroot $(@D) mount -t proc proc /proc
	cp $(BUILDIN) $@
	#echo "APT::Get::AllowUnauthenticated 1 ;" > $(@D)/etc/apt/apt.conf.d/80auth
	#find $(DIBUILD)/pkg-lists/ -name \*.cfg -exec echo -e "zfs-modules\npartman-zfs" >> {} \;

zfs: $(ZFS)

$(ZFS): zfs/configure
	cd zfs && dpkg-buildpackage $(CONCURRENCY)

$(SPL): spl/configure
	cd spl && dpkg-buildpackage $(CONCURRENCY)

$(DIBUILD)/config/common: common $(CHROOT)/build
	@[ -d $(@D) ] || mkdir -p $(@D)
	cat $< > $@

clean:
	rm -rf tmp $(TESTDISK) images $(CONF) $(PMZFS)
	rm -f $(wildcard *deb) $(wildcard zfs/*deb) $(wildcard zfs/*rpm)
	-cd $(UDEBS)/partman-zfs && debian/rules clean
	-cd zfs && make maintainer-clean || true
	-cd spl && make maintainer-clean || true
	sudo umount $(CHROOT)/proc || true
	sudo rm -rf $(CHROOT)
