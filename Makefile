.DELETE_ON_ERROR:
.PHONY: all world test clean kernel udebs cleanchroot clobber

# Kernel version
UPSTREAM:=3.5.3
KVER:=$(UPSTREAM)-1
ZFSVER:=0.6.0~rc10
ZFSFVER:=$(ZFSVER)-2_amd64
SPLFVER:=$(ZFSVER)-2_amd64

CHROOT:=unstable
DI:=debian-installer_20120828
DIBUILD:=$(CHROOT)/s-i/installer/build
WGET:=wget --no-use-server-timestamps
DBUILD:=dpkg-buildpackage -k9978711C

# Helper scripts
BUILD:=build
BUILDIN:=innerbuild
BUILDU:=udebbuild
BUILDW:=worldbuild
BUILDK:=kernelbuild
MAKECD:=makecd
RUNCD:=runcd
UPDATE:=update

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=profiles/SprezzOS.conf
SEED:=profiles/SprezzOS.preseed
PROFILE:=profiles/SprezzOS.packages

BASHRC:=bashrc
IMG:=SprezzOS.iso
TESTDISK:=kvmdisk.img
PACKAGES:=packages.tgz
CONFIN:=SprezzOS.conf.in
SEEDIN:=SprezzOS.preseed.in
PACKIN:=SprezzOS.packages.in
DIDEB:=/s-i/$(DI)_amd64.deb
KERNBALL:=linux-$(UPSTREAM).tar.bz2
WORLD:=$(CHROOT)/world/README
FONT:=unicode.pf2
KERNDEB:=$(CHROOT)/linux-image-$(KVER)-amd64_$(KVER)_amd64.deb
ZFSDEB:=zfs_$(ZFSFVER).deb
SPLDEB:=spl_$(SPLFVER).deb
GRUBCONF:=grub.cfg
EXCLUDES:=excludes
THEME:=splash.png sprezzos.theme

# FIXME we've stuffed the gconv files necessary for growlight in here
LIBCUDEB:=libc6-udeb_2.13-SprezzOS36_amd64.udeb

all: $(IMG)

test: $(RUNCD) $(IMG)
	./$< $(TESTDISK) $(IMG)

# External package creation
world: $(WORLD) $(CHROOT)/$(BUILDW)
	sudo chroot $(CHROOT) /$(BUILDW)

# ISO creation
DEBS:=$(KERNDEB) $(CHROOT)/$(SPLDEB) $(CHROOT)/$(ZFSDEB)

$(IMG): $(MAKECD) $(CONF) $(PROFILE) $(CHROOT)/$(DIDEB) $(FONT) $(THEME) $(DEBS) $(GRUBCONF) $(EXCLUDES)
	./$< -f $@ $(KERNDEB) $(ZFSFVER) $(CHROOT)/$(DIDEB)

$(CHROOT)/$(SPLDEB): $(CHROOT)/$(BUILDIN)
	$(WGET) -O$@ http://www.sprezzatech.com/apt/pool/main/s/spl/$(SPLDEB)

$(CHROOT)/$(ZFSDEB): $(CHROOT)/$(BUILDIN)
	$(WGET) -O$@ http://www.sprezzatech.com/apt/pool/main/z/zfs/$(ZFSDEB)

$(KERNDEB): $(CHROOT)/$(BUILDIN)
	$(WGET) -O- http://www.sprezzatech.com/apt/pool/main/s/sprezzos-grub2theme/sprezzos-grub2theme_1.0.7_all.deb > $(CHROOT)/sprezzos-grub2theme_1.0.7_all.deb
	$(WGET) -O- http://www.sprezzatech.com/apt/pool/main/l/linux-2.6/$(notdir $(KERNDEB)) > $@

$(PROFILE): $(PACKIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && echo "linux-image-$(KVER)-amd64" && cat $^ ) > $@

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && \
		cat $^ && \
		echo custom_installer=\"$(shell pwd)/dest\" ) > $@

kernel: $(CHROOT)/linux-$(UPSTREAM)/debian $(CHROOT)/$(BUILDK) $(CHROOT)/zfs-$(ZFSVER)/debian $(CHROOT)/spl-$(ZFSVER)/debian
	@[ ! -d $(CHROOT)/orig ] || sudo rm -rf $(CHROOT)/orig
	sudo chroot $(CHROOT) /$(BUILDK) $(UPSTREAM) $(ZFSVER)

$(CHROOT)/$(DIDEB): $(CHROOT)/$(BUILDIN) $(CHROOT)/s-i/installer/build/sources.list.udeb.local $(CHROOT)/s-i/installer/build/localudebs/$(LIBCUDEB)
	sudo chroot $(CHROOT) /$(BUILDIN)

udebs: $(CHROOT)/$(BUILDU)
	sudo chroot $(CHROOT) /$(BUILDU)

$(CHROOT)/s-i/installer/build/sources.list.udeb.local: sources.list.udeb.local $(CHROOT)/$(BUILDIN)
	cp -fv $< $@

$(CHROOT)/linux-$(UPSTREAM)/debian: $(CHROOT)/$(KERNBALL) $(WORLD)
	sudo chroot $(CHROOT) tar xjf $(<F)
	sudo chroot $(CHROOT) cp -r world/linux linux-$(UPSTREAM)/debian

$(WORLD): $(CHROOT)/$(BUILDIN)
	@[ -r $@ ] || sudo chroot $(CHROOT) git clone git://github.com/dankamongmen/sprezzos-world.git world

$(CHROOT)/zfs-$(ZFSVER)/debian: $(CHROOT)/$(BUILDIN) $(WORLD)
	sudo chroot $(CHROOT) git clone https://github.com/zfsonlinux/zfs.git zfs-$(ZFSVER)
	sudo chroot $(CHROOT) cp -r world/zfs zfs-$(ZFSVER)/debian

$(CHROOT)/spl-$(ZFSVER)/debian: $(CHROOT)/$(BUILDIN) $(WORLD)
	sudo chroot $(CHROOT) git clone https://github.com/zfsonlinux/spl.git spl-$(ZFSVER)
	sudo chroot $(CHROOT) cp -r world/spl spl-$(ZFSVER)/debian

$(CHROOT)/$(KERNBALL): $(CHROOT)/$(BUILDIN)
	$(WGET) -P $(CHROOT) ftp://ftp.kernel.org/pub/linux/kernel/v3.x/linux-$(UPSTREAM).tar.bz2

$(CHROOT)/$(BUILDK): $(BUILDK) $(CHROOT)/$(BUILDIN)
	cp $< $@

$(CHROOT)/$(BUILDU): $(BUILDU) $(CHROOT)/$(BUILDIN)
	cp $< $@

$(CHROOT)/$(BUILDW): $(BUILDW) $(CHROOT)/$(BUILDIN)
	cp $< $@

$(CHROOT)/$(BUILDIN): $(BUILD) $(BUILDIN) $(PACKAGES) $(SEED) local $(BASHRC)
	@[ ! -e $(@D) ] || { echo "$(@D) exists. Remove it with 'make cleanchroot'." >&2 ; exit 1 ; }
	./$< $(@D)
	cp -fv $< $@
	cp -fv $(BUILDIN) $@

$(CHROOT)/s-i/installer/build/localudebs/$(LIBCUDEB): $(LIBCUDEB) $(CHROOT)/$(BUILDIN)
	cp -fv $< $(@D)

$(SEED): $(SEEDIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && cat $^ && echo "d-i base-installer/kernel/image select linux-image-$(KVER)-amd64" ) > $@

cleanchroot:
	sudo umount $(CHROOT)/proc $(CHROOT)/sys $(CHROOT)/dev/pts || true
	sudo rm -rf $(CHROOT)

$(PACKAGES): $(UPDATE)
	./$< $@

#$(FONT): /usr/share/fonts/X11/misc/ter-u28b_unicode.pcf.gz
$(FONT): /usr/share/fonts/X11/misc/ter-u20b_unicode.pcf.gz
	grub-mkfont -v -a --no-bitmap $< -o $@

clean: cleanchroot
	rm -rf tmp $(TESTDISK) images $(IMG) profiles
	sudo rm -rf dibuild

clobber: clean
	rm -f $(PACKAGES) $(FONT)
