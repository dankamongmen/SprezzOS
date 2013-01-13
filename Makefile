.DELETE_ON_ERROR:
.PHONY: all world test clean kernel udebs cleanchroot clobber

# Kernel version
# The x.y.0 releases are just "x.y" upstream, annoyingly. Come x.y.0, LINUXORIG
# goes to a major.minor, and .0 is appended to UPSTREAM. Sucks, I know.
LINUXORIG:=3.7.1
UPSTREAM:=$(LINUXORIG)
#LINUXORIG:=3.7
#UPSTREAM:=$(LINUXORIG).0

KVER:=$(UPSTREAM)-1
ABINAME:=3.7.0-1

CHROOT:=unstable
DI:=debian-installer_20121115
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
KERNBALL:=linux-$(LINUXORIG).tar.bz2
WORLD:=$(CHROOT)/world/README
FONT:=unicode.pf2
KERNDEB:=linux-image-$(ABINAME)-amd64_$(ABINAME)_amd64.deb
GRUBTHEMEDEB:=sprezzos-grub2theme_1.0.8-SprezzOS1_all.deb
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
DEBS:=$(KERNDEB) $(GRUBTHEMEDEB)

$(IMG): $(MAKECD) $(CONF) $(PROFILE) $(CHROOT)/$(DIDEB) $(FONT) $(THEME) $(DEBS) $(GRUBCONF) $(EXCLUDES)
	./$< -f $@ $(KERNDEB) $(ZFSFVER) $(CHROOT)/$(DIDEB)

$(KERNDEB):
	$(WGET) -O$@ http://www.sprezzatech.com/apt/pool/main/l/linux-2.6/$(notdir $(KERNDEB))

$(GRUBTHEMEDEB):
	$(WGET) -O$@ http://www.sprezzatech.com/apt/pool/main/s/sprezzos-grub2theme/$(notdir $(GRUBTHEMEDEB))

$(PROFILE): $(PACKIN) $(MAKEFILE)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && echo "linux-image-amd64" && cat $^ ) > $@
	#( echo "# Automatically generated by Make" && echo "linux-image-$(ABINAME)-amd64" && cat $^ ) > $@

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && \
		cat $^ && \
		echo custom_installer=\"$(shell pwd)/dest\" ) > $@

kernel: $(CHROOT)/linux-$(UPSTREAM)/debian $(CHROOT)/$(BUILDK)
	@[ ! -d $(CHROOT)/orig ] || sudo rm -rf $(CHROOT)/orig
	sudo chroot $(CHROOT) /$(BUILDK) $(UPSTREAM)

$(CHROOT)/$(DIDEB): $(CHROOT)/$(BUILDIN) $(CHROOT)/s-i/installer/build/sources.list.udeb.local $(CHROOT)/s-i/installer/build/localudebs/$(LIBCUDEB)
	sudo chroot $(CHROOT) /$(BUILDIN)

udebs: $(CHROOT)/$(BUILDU)
	sudo chroot $(CHROOT) /$(BUILDU)

$(CHROOT)/s-i/installer/build/sources.list.udeb.local: sources.list.udeb.local $(CHROOT)/$(BUILDIN)
	sudo cp -fv $< $@

$(CHROOT)/linux-$(UPSTREAM)/debian: $(CHROOT)/$(KERNBALL) $(WORLD)
	sudo chroot $(CHROOT) tar xjf $(<F)
	sudo chroot $(CHROOT) cp -r world/packaging/linux/debian linux-$(LINUXORIG)/debian

$(WORLD): $(CHROOT)/$(BUILDIN)
	@[ -r $@ ] || sudo chroot $(CHROOT) git clone git://github.com/dankamongmen/sprezzos-world.git world

$(CHROOT)/$(KERNBALL): $(CHROOT)/$(BUILDIN)
	sudo $(WGET) -P $(CHROOT) ftp://ftp.kernel.org/pub/linux/kernel/v3.x/linux-$(LINUXORIG).tar.bz2

$(CHROOT)/$(BUILDK): $(BUILDK) $(CHROOT)/$(BUILDIN)
	sudo cp -fv $< $@

$(CHROOT)/$(BUILDU): $(BUILDU) $(CHROOT)/$(BUILDIN)
	sudo cp -fv $< $@

$(CHROOT)/$(BUILDW): $(BUILDW) $(CHROOT)/$(BUILDIN)
	sudo cp -fv $< $@

$(CHROOT)/$(BUILDIN): $(BUILD) $(BUILDIN) $(PACKAGES) $(SEED) local $(BASHRC)
	@[ ! -e $(@D) ] || { echo "$(@D) exists. Remove it with 'make cleanchroot'." >&2 ; exit 1 ; }
	sudo ./$< $(@D)
	sudo cp -fv $< $(BUILDIN) $(@D)

$(CHROOT)/s-i/installer/build/localudebs/$(LIBCUDEB): $(LIBCUDEB) $(CHROOT)/$(BUILDIN)
	sudo cp -fv $< $(@D)

$(SEED): $(SEEDIN) $(MAKEFILE)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && cat $^ && echo "d-i base-installer/kernel/image select linux-image-$(ABINAME)-amd64" ) > $@

cleanchroot:
	sudo umount $(CHROOT)/proc/sys/fs/binfmt_misc || true
	sudo umount $(CHROOT)/proc $(CHROOT)/sys $(CHROOT)/dev/pts || true
	sudo rm -rf $(CHROOT)

$(PACKAGES): $(UPDATE)
	./$< $@

#$(FONT): /usr/share/fonts/X11/misc/ter-u28b_unicode.pcf.gz
$(FONT): /usr/share/fonts/X11/misc/ter-u20b_unicode.pcf.gz
	grub-mkfont -v -a --no-bitmap $< -o $@

clean: cleanchroot
	rm -rf -- tmp $(wildcard $(TESTDISK)*) images $(IMG) profiles $(DEBS)
	sudo rm -rf -- dibuild

clobber: clean
	rm -f -- $(PACKAGES) $(FONT)
