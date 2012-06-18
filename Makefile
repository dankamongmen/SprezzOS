.DELETE_ON_ERROR:
.PHONY: all test clean cleanchroot clobber subupdate

# Kernel version
UPSTREAM:=3.4.3
KVER:=$(UPSTREAM)-1
ZFSVER:=0.6.0~rc9

CHROOT:=unstable
DI:=debian-installer_20120509
DIBUILD:=$(CHROOT)/d-i/installer/build

# Helper scripts
BUILD:=build
BUILDIN:=innerbuild
MAKECD:=makecd
RUNCD:=runcd
UPDATE:=update

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=$(shell pwd)/profiles/SprezzOS.conf

IMG:=SprezzOS.iso
TESTDISK:=kvmdisk.img
PACKAGES:=packages.tgz
CONFIN:=SprezzOS.conf.in
DIDEB:=/d-i/$(DI)_amd64.deb
KERNBALL:=linux-$(UPSTREAM).tar.bz2
PROFILE:=profiles/SprezzOS.packages

all: $(IMG)

test: $(RUNCD) $(TESTDISK) all
	./$< $(TESTDISK) $(ISO)

$(IMG): $(MAKECD) $(CONF) $(PROFILE) $(CHROOT)/$(DIDEB)
	./$< $@ $(KVER)

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && cat $^ && echo custom_installer=\"$(shell pwd)/dest\" ) > $@

$(CHROOT)/$(DIDEB): $(CHROOT)/linux-$(UPSTREAM)/debian
	sudo chroot $(CHROOT) /$(BUILDIN) $(UPSTREAM) $(ZFSVER)

$(CHROOT)/linux-$(UPSTREAM)/debian: $(CHROOT)/$(KERNBALL)
	sudo chroot $(CHROOT) tar xjf $(<F)
	sudo chroot $(CHROOT) git clone git://github.com/dankamongmen/sprezzos-kernel-packaging.git linux-$(UPSTREAM)/debian

$(CHROOT)/$(KERNBALL): $(CHROOT)/$(BUILDIN)
	wget -P $(CHROOT) ftp://ftp.kernel.org/pub/linux/kernel/v3.x/linux-$(UPSTREAM).tar.bz2

$(CHROOT)/$(BUILDIN): $(BUILD) $(BUILDIN) $(PACKAGES)
	@! [ -e $(@D) ] || { echo "$(@D) exists. Remove it with 'make cleanchroot'." >&2 ; exit 1 ; }
	./$< $(@D)
	cp $(BUILDIN) $@

cleanchroot:
	sudo umount $(CHROOT)/proc $(CHROOT)/sys || true
	sudo rm -rf $(CHROOT)

$(PACKAGES): $(UPDATE)
	./$< $@

subupdate:
	cd fwts && git pull origin HEAD && cd -
	git submodule update

clean: cleanchroot
	rm -rf tmp $(TESTDISK) images $(CONF) $(IMG)

clobber: clean
	rm -f $(PACKAGES)
