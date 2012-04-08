.PHONY: all test update clean clobber nukefromorbit spl zfs

DI:=debian-installer
DIBUILD:=$(DI)/build
CHROOT:=unstable

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=$(shell pwd)/cdd.conf
CONFIN:=$(shell pwd)/cdd.conf.in
ZFS:=$(shell pwd)/zfs/zfs_0.6.0-1_amd64.deb
SPL:=$(shell pwd)/spl/spl_0.6.0-1_amd64.deb

PROFILE:=profiles/SprezzOS.packages
PROFILEIN:=SprezzOS.packages
IMG:=images/debian-unstable-amd64-CD-1.iso
TESTDISK:=kvmdisk.img
SLIST:=sources.list.udeb.local

# don't yet use $(DIIMG), our custom build of debian-installer
all: $(IMG)

test: $(TESTDISK) all
	kvm -cdrom $(IMG) -hda $<

$(TESTDISK):
	kvm-img create $@ 40G

$(IMG): $(CONF) $(PROFILE) $(ZFS) $(DIIMG) $(PROFILE)
	simple-cdd --conf $< --dist sid --profiles-udeb-dist sid \
		--profiles SprezzOS --auto-profiles SprezzOS \
		--local-packages $(ZFS)

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( cat $^ && echo "custom_installer=$(shell pwd)/dest" ) > $@

$(DIIMG): $(DIBUILD)/$(SLIST) $(DIBUILD)/config/common $(CHROOT)/build
	sudo chroot $(@D) bash -c build

$(CHROOT)/build:
	sudo debootstrap --variant=buildd unstable $(@D) http://ftp.us.debian.org/debian
	sudo chroot $(@D) mount -t proc procfs /proc
	sudo chroot $(@D) apt-get install locales autoconf udev
	sudo chroot $(@D) dpkg-reconfigure locales
	sudo chroot $(@D) apt-get build-dep debian-installer
	sudo cp -r $(DI) $(@D)/root/
	echo "cd root/$(DI) && debian/rules binary" > $@

zfs: $(ZFS)

$(ZFS): $(SPL) zfs/Makefile
	cd zfs && make deb

$(SPL): spl/Makefile
	cd spl && make deb

zfs/Makefile: zfs/configure
	cd zfs && ./configure

spl/Makefile: spl/configure
	cd spl && ./configure

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
	rm -rf tmp $(TESTDISK) images $(PROFILE) $(CONF)
	rm -f $(wildcard *deb) $(wildcard zfs/*deb) $(wildcard zfs/*rpm)
	-cd zfs && make maintainer-clean || true
	-cd spl && make maintainer-clean || true
	rm -rf $(CHROOT)

clobber:
	cd $(DIBUILD) && make reallyclean

nukefromorbit:
	rm -rf $(DI)
