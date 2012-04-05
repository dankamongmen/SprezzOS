.PHONY: all test update clean

CONF:=$(shell pwd)/cdd.conf
IMG:=images/debian-unstable-amd64-CD-1.iso
TESTDISK:=kvmdisk.img

all: $(IMG)

test: $(TESTDISK) all
	kvm -cdrom $(IMG) -hda $<

$(TESTDISK):
	kvm-img create $@ 40G

$(IMG): $(CONF)
	simple-cdd --conf $< --dist sid --profiles-udeb-dist sid \
		--profiles SprezzOS --auto-profiles SprezzOS

update:
	cd debian-installer && svn up && mr -r update

clean:
	rm -rf tmp $(TESTDISK) images
