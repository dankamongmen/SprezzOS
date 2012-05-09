/*
 * Copyright (C) 2010-2012 Canonical
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 */
#include "fwts.h"

#ifdef FWTS_ARCH_INTEL

#define BIOS32_SD_REGION_START	(0x000e0000)
#define BIOS32_SD_REGION_END  	(0x000fffff)
#define BIOS32_SD_REGION_SIZE	(BIOS32_SD_REGION_END - BIOS32_SD_REGION_START)

typedef struct {
	uint8_t		signature[4];
	uint32_t	entry_point;
	uint8_t		revision_level;
	uint8_t		length;
	uint8_t		checksum;
	uint8_t		reserved[5];
}  __attribute__ ((packed)) fwts_bios32_service_directory;

static int bios32_init(fwts_framework *fw)
{
	if (fw->firmware_type != FWTS_FIRMWARE_BIOS) {
		fwts_log_info(fw,
			"Machine is not using traditional BIOS firmware, "
			"skipping test.");
		return FWTS_SKIP;
	}

	return FWTS_OK;
}

static int bios32_test1(fwts_framework *fw)
{
	uint8_t *mem;
	int i;
	int found = 0;

	fwts_log_info(fw,
		"This test tries to find and sanity check the BIOS32 Service "
		"Directory as defined in the Standard BIOS 32-bit Service "
		"Directory Proposal, Revision 0.4 May 24, 1993, Phoenix "
		"Technologies Ltd and also the PCI BIOS specification.");

        if ((mem = fwts_mmap(BIOS32_SD_REGION_START, 
			BIOS32_SD_REGION_SIZE)) == FWTS_MAP_FAILED) {
		fwts_log_error(fw, "Cannot mmap BIOS32 region.");
		return FWTS_ERROR;
	}

	for (i=0; i<BIOS32_SD_REGION_SIZE; i+= 16) {
		if ((*(mem+i)   == '_') &&
		    (*(mem+i+1) == '3') &&
		    (*(mem+i+2) == '2') &&
		    (*(mem+i+3) == '_')) {
			fwts_bios32_service_directory *bios32 =
				(fwts_bios32_service_directory *)(mem+i);

			fwts_log_info(fw,
				"Found BIOS32 Service Directory at 0x%8.8x",
				BIOS32_SD_REGION_START+i);
			fwts_log_info_verbatum(fw, "  Signature  : %4.4s", 
				bios32->signature);
			fwts_log_info_verbatum(fw, "  Entry Point: 0x%8.8x",
				bios32->entry_point);
			fwts_log_info_verbatum(fw, "  Revsion    : 0x%2.2x",
				bios32->revision_level);
			fwts_log_info_verbatum(fw, "  Length     : 0x%2.2x",
				bios32->length);
			fwts_log_info_verbatum(fw, "  Checksum   : 0x%2.2x",
				bios32->checksum);
			fwts_log_nl(fw);

			if (bios32->entry_point >= 0x100000) {
				fwts_failed(fw, LOG_LEVEL_HIGH,
					"BIOS32SrvDirEntryPointHighMem",
					"Service Directory Entry Point 0x%8.8x "
					"is in high memory and cannot be used "
					"by the kernel.",
					bios32->entry_point);
				fwts_tag_failed(fw, FWTS_TAG_BIOS);
			} else
				fwts_passed(fw, "Service Directory Entry Point "
					"0x%8.8x is not in high memory.",
					bios32->entry_point);

			if (bios32->length != 1) {
				fwts_failed(fw, LOG_LEVEL_HIGH,
					"BIOS32SrvDirEntryLength",
					"Service Directory Length is 0x%8.8x, "
					"expected 1 (1 x 16 bytes).",
					bios32->length);
				fwts_tag_failed(fw, FWTS_TAG_BIOS);
			} else
				fwts_passed(fw,
					"Service Directory Length is 1 "
					"(1 x 16 bytes) as expected.");

			if (bios32->revision_level != 0) {
				fwts_failed(fw, LOG_LEVEL_HIGH,
					"BIOS32SrvDirRevision",
					"Service Directory Revision is 0x%2.2x,"
					" only version 0 is supported by the "
					"kernel.",
					bios32->revision_level);
				fwts_tag_failed(fw, FWTS_TAG_BIOS);
			} else
				fwts_passed(fw,
					"Service Directory Revision is 0x%2.2x "
					"and is supported by the kernel.",
					bios32->revision_level);

			if (fwts_checksum(mem + i, 16) != 0) {
				fwts_failed(fw, LOG_LEVEL_HIGH, 
					"BIOS32SrvDirCheckSum",
					"Service Directory checksum failed.");
				fwts_tag_failed(fw, FWTS_TAG_BIOS);
			} else
				fwts_passed(fw,
					"Service Directory checksum passed.");
			found++;
		}
	}

	if (found == 0)
		fwts_log_info(fw, "Could not find BIOS32 Service Directory.");
	else if (found > 1) {
		fwts_failed(fw, LOG_LEVEL_HIGH,
			"BIOS32MultipleSrvDirInstances", 
			"Found %d instances of BIOS32 Service Directory, "
			"there should only be 1.", found);
		fwts_tag_failed(fw, FWTS_TAG_BIOS);
	}

        (void)fwts_munmap(mem, BIOS32_SD_REGION_SIZE);

	return FWTS_OK;
}

static fwts_framework_minor_test bios32_tests[] = {
	{ bios32_test1, "Check BIOS32 Service Directory." },
	{ NULL, NULL }
};

static fwts_framework_ops bios32_ops = {
	.description = "Check BIOS32 Service Directory.",
	.init        = bios32_init,
	.minor_tests = bios32_tests
};

FWTS_REGISTER(bios32, &bios32_ops, FWTS_TEST_ANYTIME,
	FWTS_BATCH | FWTS_ROOT_PRIV);

#endif
