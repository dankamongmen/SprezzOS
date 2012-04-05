.PHONY: all test update clean clobber

DI:=debian-installer
DIBUILD:=$(DI)/installer/build

CONF:=$(shell pwd)/cdd.conf
IMG:=images/debian-unstable-amd64-CD-1.iso
TESTDISK:=kvmdisk.img
SLIST:=sources.list.udeb.local

all: $(IMG) $(DIIMG)

test: $(TESTDISK) all
	kvm -cdrom $(IMG) -hda $<

$(TESTDISK):
	kvm-img create $@ 40G

$(IMG): $(CONF)
	simple-cdd --conf $< --dist sid --profiles-udeb-dist sid \
		--profiles SprezzOS --auto-profiles SprezzOS

$(DIIMG): $(DIBUILD)/$(SLIST)
	cd $(DIBUILD) && make build_cdrom_isolinux

$(DIBUILD)/$(SLIST): $(SLIST) $(DI)/.mrconfig
	cat $< > $@

update: $(DI)/.mrconfig
	cd $(DI) && svn up && mr update

$(DI)/.mrconfig:
	[ -d $(DI) ] || { svn co svn://svn.debian.org/svn/d-i/trunk $(DI) && \
		cd $(DI) && scripts/git-setup && mr -p checkout ; }

clean:
	rm -rf tmp $(TESTDISK) images
	cd $(DI) && svn-clean -f

clobber:
	rm -rf $(DI)
