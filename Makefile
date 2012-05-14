.DELETE_ON_ERROR:
.PHONY: all test clean cleanchroot zfs clobber

CHROOT:=unstable
DBUILDOPS:=-j8 -k9978711C
DI:=debian-installer-20120507
DIBUILD:=$(CHROOT)/$(DI)/build

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=$(shell pwd)/profiles/SprezzOS.conf
CONFIN:=$(shell pwd)/SprezzOS.conf.in
BUILDIN:=innerbuild
UDEBS:=$(shell pwd)/udebs
PMZFS:=$(UDEBS)/partman-zfs_19_all.udeb

ZMOD:=$(CHROOT)/zfs-modules_0.6.0-1_amd64.deb
ZFS:=$(CHROOT)/zfs_0.6.0-1_amd64.deb

SMOD:=$(CHROOT)/spl-modules_0.6.0-1_amd64.deb
SPL:=$(CHROOT)/spl_0.6.0-1_amd64.deb

FREETYPE:=freetype-2.4.9
LFT:=libfreetype6-udeb_2.4.9-1.1_amd64.udeb

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

#--profiles-udeb-dist $(UDEBS) #--extra-udeb-dist $(UDEBS)

$(PMZFS): $(UDEBS)/partman-zfs/debian/rules
	cd $(<D)/.. && dpkg-buildpackage $(DBUILDOPS)

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( cat $^ && echo custom_installer=\"$(shell pwd)/dest\" ) > $@

TARGUDEBS:=$(DIBUILD)/localudebs/partman-zfs_19_all.udeb
TARGUDEBS+=$(DIBUILD)/localudebs/zfs_1-1_all.udeb
TARGUDEBS+=$(CHROOT)/root/udebs/partman-zfs_19_all.udeb
TARGUDEBS+=$(CHROOT)/root/udebs/zfs_1-1_all.udeb

$(DEBS) $(TARGUDEBS) $(DIIMG): $(DIBUILD)/config/common $(CHROOT)/$(BUILDIN)
	sudo chroot $(CHROOT) /$(BUILDIN)

$(CHROOT)/root/udebs/%.udeb: $(UDEBS)/%.udeb $(CHROOT)/$(BUILDIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp $< $@

$(DIBUILD)/localudebs/%.udeb: $(UDEBS)/%.udeb $(CHROOT)/$(BUILDIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	cp $< $@

packages.tgz: update
	./update $@

$(CHROOT)/linux-stable:
	cd $(@D) && git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git

$(LFT):
	cd $(FREETYPE) && dpkg-buildpackage $(DBUILDOPS)

$(CHROOT)/$(BUILDIN): $(BUILDIN) common build $(LFT) packages.tgz
	@! [ -e $(@D) ] || { echo "$(@D) exists. Remove it with 'make cleanchroot'." >&2 ; exit 1 ; }
	./build $(@D) $(LFT)
	cp $(BUILDIN) $@
	#sudo debootstrap --include=debian-keyring,kernel-wedge,automake,autoconf,udev,vim-nox,locales --variant=buildd unstable $(@D) http://ftp.us.debian.org/debian
	#sudo chroot $(@D) mount -t proc procfs /proc
	#sudo chroot $(@D) dpkg-reconfigure locales
	#echo "deb-src http://ftp.us.debian.org/debian/ unstable main non-free contrib" | sudo tee -a $(CHROOT)/etc/apt/sources.list
	#sudo chroot $(@D) apt-get -y update
	#sudo chroot $(@D) apt-get -y build-dep debian-installer
	#sudo chroot $(@D) apt-get source debian-installer
	#sudo chroot $(@D) umount /proc
	#sudo chown -R $(shell whoami) $(@D)
	#sudo chroot $(@D) mount -t proc proc /proc
	#echo "APT::Get::AllowUnauthenticated 1 ;" > $(@D)/etc/apt/apt.conf.d/80auth
	#find $(DIBUILD)/pkg-lists/ -name \*.cfg -exec echo -e "zfs-modules\npartman-zfs" >> {} \;

zfs: $(ZFS)

$(DIBUILD)/config/common: common $(CHROOT)/$(BUILDIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	cat $< > $@

cleanchroot:
	sudo umount $(CHROOT)/proc $(CHROOT)/sys || true
	sudo rm -rf $(CHROOT)

clean: cleanchroot
	rm -rf tmp $(TESTDISK) images $(CONF) $(PMZFS)
	rm -f $(wildcard *deb) $(wildcard zfs/*deb) $(wildcard zfs/*rpm)
	-cd $(UDEBS)/partman-zfs && debian/rules clean
	-cd $(FREETYPE) && debian/rules clean

clobber: clean
	rm -f packages.tgz
