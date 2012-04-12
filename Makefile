.DELETE_ON_ERROR:
.PHONY: all test clean zfs

DI:=debian-installer
CHROOT:=unstable
DIBUILD:=$(CHROOT)/root/$(DI)/build

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=$(shell pwd)/cdd.conf
CONFIN:=$(shell pwd)/cdd.conf.in
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
SLIST:=sources.list.udeb.local
DIIMG:=dest/netboot/mini.iso
CPDIIMG:=tmp/mirror/dists/sid/main/installer-amd64/current/images/netboot
DIDEB:=$(shell pwd)/unstable/root/debian-installer_201204xy_amd64.deb

all: $(IMG)

test: $(TESTDISK) all
	kvm -cdrom $(IMG) -hda $< -boot d

$(TESTDISK):
	kvm-img create $@ 40G

$(IMG): $(CONF) $(PROFILE) $(ZFS) $(SPL) $(CPDIIMG) $(PMZFS)
	rm -rf tmp
	build-simple-cdd --conf $< --dist sid --profiles SprezzOS \
		--auto-profiles SprezzOS \
		--local-packages $(ZFS),$(SPL),$(ZMOD),$(SMOD),$(shell pwd)/unstable/debian-installer_20120327_amd64.deb
		#--local-packages $(ZFS),$(SPL),$(ZMOD),$(SMOD),$(DIDEB)

$(CPDIIMG): $(DIIMG)
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp -r $(wildcard dest/*) $(@D)

#--profiles-udeb-dist $(UDEBS) #--extra-udeb-dist $(UDEBS)

$(PMZFS): $(UDEBS)/partman-zfs/debian/rules
	cd $(<D)/.. && dpkg-buildpackage -sgpg -uc -us -b

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( cat $^ && echo "custom_installer=$(shell pwd)/dest" ) > $@

TARGUDEBS:=$(DIBUILD)/localudebs/partman-zfs_1-1_all.udeb
TARGUDEBS+=$(DIBUILD)/localudebs/zfs-modules_0.6.0-1_amd64.udeb
TARGUDEBS+=$(CHROOT)/root/udebs/partman-zfs_1-1_all.udeb
TARGUDEBS+=$(CHROOT)/root/udebs/zfs-modules_0.6.0-1_amd64.udeb

$(DIIMG): $(DIBUILD)/$(SLIST) $(DIBUILD)/config/common $(CHROOT)/build $(TARGUDEBS)
	sudo chroot $(CHROOT) /build

$(UDEBS)/zfs-modules_0.6.0-1_amd64.udeb: zfs/zfs-modules_0.6.0-1_amd64.deb
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp $< $@

$(CHROOT)/root/udebs/%.udeb: $(UDEBS)/%.udeb $(CHROOT)/build
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp $< $@

$(DIBUILD)/localudebs/%.udeb: $(UDEBS)/%.udeb $(CHROOT)/build
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp $< $@

$(CHROOT)/build: $(BUILDIN) common
	sudo debootstrap --include=autoconf,udev,locales --variant=buildd unstable $(@D) http://ftp.us.debian.org/debian
	sudo chroot $(@D) mount -t proc procfs /proc
	sudo chroot $(@D) dpkg-reconfigure locales
	echo "deb-src http://ftp.us.debian.org/debian/ sid main non-free contrib" | sudo tee -a $(CHROOT)/etc/apt/sources.list
	sudo chroot $(@D) apt-get -y update
	sudo chroot $(@D) apt-get -y build-dep debian-installer
	sudo chroot $(@D) apt-get source debian-installer
	sudo chroot $(@D) umount /proc
	sudo chown -R $(shell whoami) $(@D)
	sudo chroot $(@D) mount -t proc proc /proc
	echo "APT::Get::AllowUnauthenticated 1 ;" > $(@D)/etc/apt/apt.conf.d/80auth
	sudo cp $(BUILDIN) $@
	#find $(DIBUILD)/pkg-lists/ -name \*.cfg -exec echo -e "zfs-modules\npartman-zfs" >> {} \;

zfs: $(ZFS)

$(ZFS): zfs/configure
	cd zfs && ./configure && make deb

$(SPL): spl/configure
	cd spl && ./configure && make deb

$(DIBUILD)/config/common: common $(CHROOT)/build
	@[ -d $(@D) ] || mkdir -p $(@D)
	cat $< > $@

$(DIBUILD)/$(SLIST): $(SLIST) $(CHROOT)/build
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
