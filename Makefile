.PHONY: all test update clean spl zfs

DI:=debian-installer
CHROOT:=unstable
DIBUILD:=$(CHROOT)/root/$(DI)/build

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=$(shell pwd)/cdd.conf
CONFIN:=$(shell pwd)/cdd.conf.in
BUILDIN:=chroot-build
ZFS:=$(shell pwd)/zfs/zfs_0.6.0-1_amd64.deb
SPL:=$(shell pwd)/spl/spl_0.6.0-1_amd64.deb

PROFILE:=profiles/SprezzOS.packages
IMG:=images/debian-unstable-amd64-CD-1.iso
TESTDISK:=kvmdisk.img
SLIST:=sources.list.udeb.local
DIIMG:=$(CHROOT)/root/debian-installer_201204xy_amd64.deb

all: $(IMG)

test: $(TESTDISK) all
	kvm -cdrom $(IMG) -hda $<

$(TESTDISK):
	kvm-img create $@ 40G

$(IMG): $(CONF) $(PROFILE) $(ZFS) $(DIIMG)
	simple-cdd --conf $< --dist sid --profiles-udeb-dist sid \
		--profiles SprezzOS --auto-profiles SprezzOS \
		--local-packages $(ZFS)

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( cat $^ && echo "custom_installer=$(shell pwd)/dest" ) > $@

$(DIIMG): $(DIBUILD)/$(SLIST) $(DIBUILD)/config/common $(CHROOT)/build
	sudo chroot $(CHROOT) /build

$(CHROOT)/build: $(BUILDIN)
	sudo debootstrap --include=git,autoconf,udev,locales --variant=buildd unstable $(@D) http://ftp.us.debian.org/debian
	sudo chroot $(@D) mount -t proc procfs /proc
	sudo chroot $(@D) dpkg-reconfigure locales
	echo "deb-src http://ftp.us.debian.org/debian/ sid main non-free contrib" | sudo tee -a $(CHROOT)/etc/apt/sources.list
	sudo chroot $(@D) apt-get update
	sudo chroot $(@D) apt-get build-dep debian-installer
	sudo chroot $(@D) git clone git://git.debian.org/d-i/debian-installer.git /root/debian-installer
	sudo chroot $(@D) umount /proc
	sudo chown -R $(shell whoami) $(@D)
	sudo chroot $(@D) mount /proc
	sudo cp $(BUILDIN) $@

zfs: $(ZFS)

$(ZFS): $(SPL) zfs/Makefile
	cd zfs && make deb

$(SPL): spl/Makefile
	cd spl && make deb

zfs/Makefile: zfs/configure
	cd zfs && ./configure

spl/Makefile: spl/configure
	cd spl && ./configure

$(DIBUILD)/config/common: common $(CHROOT)/build
	@[ -d $(@D) ] || mkdir -p $(@D)
	cat $< > $@

$(DIBUILD)/$(SLIST): $(SLIST) $(CHROOT)/build
	@[ -d $(@D) ] || mkdir -p $(@D)
	cat $< > $@

update: $(DI)/.mrconfig
	git submodule update
	cd $(DI) && mr update

clean:
	rm -rf tmp $(TESTDISK) images $(CONF)
	rm -f $(wildcard *deb) $(wildcard zfs/*deb) $(wildcard zfs/*rpm)
	-cd zfs && make maintainer-clean || true
	-cd spl && make maintainer-clean || true
	sudo umount $(CHROOT)/proc || true
	sudo rm -rf $(CHROOT)
