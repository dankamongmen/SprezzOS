.DELETE_ON_ERROR:
.PHONY: all test clean cleanchroot clobber

CHROOT:=unstable
DBUILDOPS:=-j8 -k9978711C
DI:=debian-installer-20120509
DIBUILD:=$(CHROOT)/d-i/installer/build

# Helper scripts
BUILD:=build
BUILDIN:=innerbuild
MAKECD:=makecd
RUNCD:=runcd
UPDATE:=update

# simple-cdd builds from subdirs, and needs full paths as input
CONF:=$(shell pwd)/profiles/SprezzOS.conf
CONFIN:=$(shell pwd)/SprezzOS.conf.in

IMG:=SprezzOS.iso
TESTDISK:=kvmdisk.img
PACKAGES:=package.tgz
WORLD:=$(shell pwd)/world
PROFILE:=profiles/SprezzOS.packages
DIDEB:=$(shell pwd)/unstable/$(DI)_amd64.deb

DEBS:=$(DIDEB) $(SPL) $(ZFS)

all: $(IMG)

test: $(RUNCD) $(TESTDISK) all
	./$< $(TESTDISK) $(ISO)

$(IMG): $(MAKECD) $(CONF) $(PROFILE) $(DIDEB)
	./$< $@

$(CONF): $(CONFIN)
	@[ -d $(@D) ] || mkdir -p $(@D)
	( echo "# Automatically generated by Make" && cat $^ && echo custom_installer=\"$(shell pwd)/dest\" ) > $@

$(DIDEB): $(CHROOT)/$(BUILDIN)
	sudo chroot $(CHROOT) /$(BUILDIN)

$(PACKAGES): $(UPDATE)
	./$< $@

$(CHROOT)/$(BUILDIN): $(BUILD) $(BUILDIN) $(PACKAGES)
	@! [ -e $(@D) ] || { echo "$(@D) exists. Remove it with 'make cleanchroot'." >&2 ; exit 1 ; }
	./< $(@D)
	cp $(BUILDIN) $@

cleanchroot:
	sudo umount $(CHROOT)/proc $(CHROOT)/sys || true
	sudo rm -rf $(CHROOT)

clean: cleanchroot
	rm -rf tmp $(TESTDISK) images $(CONF)

clobber: clean
	rm -f $(PACKAGES)
