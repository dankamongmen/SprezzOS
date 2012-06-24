.DELETE_ON_ERROR:
.PHONY: all test clean cleanchroot clobber subupdate

# Kernel version
UPSTREAM:=3.4.3
KVER:=$(UPSTREAM)-1
ZFSVER:=0.6.0~rc9

CHROOT:=unstable
DI:=debian-installer_20120509
DIBUILD:=$(CHROOT)/d-i/installer/build
WGET:=wget --no-use-server-timestamps
DBUILD:=dpkg-buildpackage -k9978711C

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
PACKIN:=SprezzOS.packages.in
DIDEB:=/d-i/$(DI)_amd64.deb
KERNBALL:=linux-$(UPSTREAM).tar.bz2
PROFILE:=profiles/SprezzOS.packages
UDK:=UDK2010.SR1.Complete.MyWorkSpace.zip
UDKDIR:=/usr/local/UDK2010
FBT:=fbterm_1.7-2_amd64.udeb

all: $(IMG)

test: $(RUNCD) $(TESTDISK) all
	./$< $(TESTDISK) $(ISO)

$(IMG): $(MAKECD) $(CONF) $(PROFILE) $(CHROOT)/$(DIDEB)
	./$< $@ $(KVER) $(ZFSVER)

$(PROFILE): $(PACKIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && echo "linux-image-$(KVER)-amd64" && cat $^ ) > $@

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && cat $^ && echo custom_installer=\"$(shell pwd)/dest\" ) > $@

$(CHROOT)/$(DIDEB): $(CHROOT)/linux-$(UPSTREAM)/debian $(CHROOT)/$(UDKDIR)/MyWorkSpace/Conf/target.txt $(CHROOT)/refind/install.sh $(CHROOT)/$(FBT)
	sudo chroot $(CHROOT) bash /$(BUILDIN) $(UPSTREAM) $(ZFSVER)

#GCCCONTROL:=gcc-control
#GCCDIR:=gcc-4.7-4.7.1
#$(CHROOT)/$(LIBSTDC): $(CHROOT)/$(BUILDIN) $(GCCCONTROL)
#	@[ ! -e $(CHROOT)/$(GCCDIR) ] || sudo rm -rf $(CHROOT)/$(GCCDIR)
#	sudo chroot $(CHROOT) apt-get source libstdc++6
#	sudo cp $(GCCCONTROL) $(CHROOT)/$(GCCDIR)/debian/control
#	sudo chroot $(CHROOT) /bin/sh -c "cd $(GCCCONTROL) && $(DBUILD) -j8"

$(CHROOT)/$(FBT): $(CHROOT)/$(BUILDIN)
	@[ ! -e $(CHROOT)/fbterm-1.7 ] || sudo rm -rf $(CHROOT)/fbterm-1.7
	cp -r fbterm-1.7 $(CHROOT)
	cp -r /media/build/sprezzos-world/fbterm $(CHROOT)/fbterm-1.7/debian
	sudo chroot $(CHROOT) /bin/sh -c "cd fbterm-1.7 && $(DBUILD) -j8"

$(CHROOT)/refind/install.sh: $(CHROOT)/$(BUILDIN)
	@[ ! -e $(@D) ] || sudo rm -rf $(@D)
	sudo chroot $(CHROOT) git clone git://git.code.sf.net/p/refind/code refind

$(CHROOT)/linux-$(UPSTREAM)/debian: $(CHROOT)/$(KERNBALL)
	sudo chroot $(CHROOT) tar xjf $(<F)
	sudo chroot $(CHROOT) git clone git://github.com/dankamongmen/sprezzos-kernel-packaging.git linux-$(UPSTREAM)/debian

$(CHROOT)/$(KERNBALL): $(CHROOT)/$(BUILDIN)
	$(WGET) -P $(CHROOT) ftp://ftp.kernel.org/pub/linux/kernel/v3.x/linux-$(UPSTREAM).tar.bz2

$(CHROOT)/$(BUILDIN): $(BUILD) $(BUILDIN) $(PACKAGES)
	@[ ! -e $(@D) ] || { echo "$(@D) exists. Remove it with 'make cleanchroot'." >&2 ; exit 1 ; }
	./$< $(@D) libstdc++6_4.7.1-1_amd64.udeb libx86-1_1.1+ds1-10_amd64.udeb
	cp $(BUILDIN) $@

cleanchroot:
	sudo umount $(CHROOT)/proc $(CHROOT)/sys $(CHROOT)/dev/pts || true
	sudo rm -rf $(CHROOT)

$(PACKAGES): $(UPDATE)
	./$< $@

$(CHROOT)/$(UDKDIR)/MyWorkSpace/Conf/target.txt: $(CHROOT)/$(UDKDIR)/UDK2010.SR1.MyWorkSpace.zip
	sudo chroot $(CHROOT) /bin/sh -c "cd $(UDKDIR) && unzip $(<F)"
	sudo chroot $(CHROOT) /bin/sh -c "cd $(UDKDIR)/MyWorkSpace && tar xvf ../BaseTools\(Unix\)_UDK2010.SR1.tar"

$(CHROOT)/$(UDKDIR)/UDK2010.SR1.MyWorkSpace.zip: $(CHROOT)/$(BUILDIN) $(UDK)
	cp -fv $(UDK) $(CHROOT)
	@[ ! -e $(@D) ] || sudo rm -rf $(@D)
	@[ -e $(@D) ] || sudo chroot $(CHROOT) mkdir $(UDKDIR)
	sudo chroot $(CHROOT) unzip $(UDK) -d $(UDKDIR)

$(UDK):
	$(WGET) -O- http://sourceforge.net/projects/edk2/files/UDK2010%20Releases/UDK2010.SR1/UDK2010.SR1.Complete.MyWorkSpace.zip/download > $@

subupdate:
	cd fwts && git pull origin HEAD && cd -
	git submodule update

clean: cleanchroot
	rm -rf tmp $(TESTDISK) images $(CONF) $(IMG)

clobber: clean
	rm -f $(PACKAGES) $(UDK)
