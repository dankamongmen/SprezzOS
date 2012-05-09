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

#ifndef __FWTS_UEFI_H__
#define __FWTS_UEFI_H__

#define FWTS_UEFI_LOAD_ACTIVE 0x00000001

typedef struct {
	uint16_t	varname[512];
	uint8_t		guid[16];
	uint64_t	datalen;
	uint8_t		data[1024];
	uint64_t	status;
	uint32_t	attributes;
} __attribute__((packed)) fwts_uefi_var;

typedef uint8_t  fwts_uefi_mac_addr[32];
typedef uint8_t  fwts_uefi_ipv4_addr[4];
typedef uint16_t fwts_uefi_ipv6_addr[8];

enum {
	FWTS_UEFI_VAR_NON_VOLATILE =		0x00000001,
	FWTS_UEFI_VAR_BOOTSERVICE_ACCESS =	0x00000002,
	FWTS_UEFI_VAR_RUNTIME_ACCESS =		0x00000004
};

#if 0
typedef struct {
	char *description;
	uefidump_func	func;
} uefidump_info;
#endif

typedef struct {
	uint8_t type;
  	uint8_t subtype;
  	uint8_t length[2];
} __attribute__ ((packed)) fwts_uefi_dev_path;

typedef struct {
        uint32_t attributes;
        uint16_t file_path_list_length;
        uint16_t description[1];
        fwts_uefi_dev_path unused_file_path_list[1];
} __attribute__((packed)) fwts_uefi_load_option;

typedef enum {
	FWTS_UEFI_HARDWARE_DEV_PATH_TYPE =		(0x01),
	FWTS_UEFI_ACPI_DEVICE_PATH_TYPE =		(0x02),
	FWTS_UEFI_MESSAGING_DEVICE_PATH_TYPE =		(0x03),
	FWTS_UEFI_MEDIA_DEVICE_PATH_TYPE =		(0x04),
	FWTS_UEFI_BIOS_DEVICE_PATH_TYPE =		(0x05),
	FWTS_UEFI_END_DEV_PATH_TYPE =			(0x7f)
} dev_path_types;

typedef enum {
	FWTS_UEFI_END_THIS_DEV_PATH_SUBTYPE = 		(0x01),
	FWTS_UEFI_END_ENTIRE_DEV_PATH_SUBTYPE = 	(0xff)
} dev_end_subtypes;

typedef enum {
	FWTS_UEFI_PCI_DEV_PATH_SUBTYPE =		(0x01),
	FWTS_UEFI_PCCARD_DEV_PATH_SUBTYPE =		(0x02),
	FWTS_UEFI_MEMORY_MAPPED_DEV_PATH_SUBTYPE =	(0x03),
	FWTS_UEFI_VENDOR_DEV_PATH_SUBTYPE =		(0x04),
	FWTS_UEFI_CONTROLLER_DEV_PATH_SUBTYPE =		(0x05)
} hw_dev_path_subtypes;

typedef enum {
	FWTS_UEFI_ACPI_DEVICE_PATH_SUBTYPE = 		(0x01),
	FWTS_UEFI_EXPANDED_ACPI_DEVICE_PATH_SUBTYPE = 	(0x02)
} acpi_dev_path_subtypes;

typedef enum {
	FWTS_UEFI_ATAPI_DEVICE_PATH_SUBTYPE = 		(0x01),
	FWTS_UEFI_SCSI_DEVICE_PATH_SUBTYPE = 		(0x02),
	FWTS_UEFI_FIBRE_CHANNEL_DEVICE_PATH_SUBTYPE = 	(0x03),
	FWTS_UEFI_1394_DEVICE_PATH_SUBTYPE = 		(0x04),
	FWTS_UEFI_USB_DEVICE_PATH_SUBTYPE =		(0x05),
	FWTS_UEFI_I2O_DEVICE_PATH_SUBTYPE =		(0x06),
	FWTS_UEFI_INFINIBAND_DEVICE_PATH_SUBTYPE =	(0x09),
	FWTS_UEFI_VENDOR_MESSAGING_DEVICE_PATH_SUBTYPE =(0x0a),
	FWTS_UEFI_MAC_ADDRESS_DEVICE_PATH_SUBTYPE =	(0x0b),
	FWTS_UEFI_IPV4_DEVICE_PATH_SUBTYPE =		(0x0c),
	FWTS_UEFI_IPV6_DEVICE_PATH_SUBTYPE =		(0x0d),
	FWTS_UEFI_UART_DEVICE_PATH_SUBTYPE =		(0x0e),
	FWTS_UEFI_USB_CLASS_DEVICE_PATH_SUBTYPE =	(0x0f)
} messaging_dev_path_subtypes;

typedef enum {
	FWTS_UEFI_HARD_DRIVE_DEVICE_PATH_SUBTYPE =	(0x01),
	FWTS_UEFI_CDROM_DEVICE_PATH_SUBTYPE =		(0x02),
	FWTS_UEFI_VENDOR_MEDIA_DEVICE_PATH_SUBTYPE =	(0x03),
	FWTS_UEFI_FILE_PATH_DEVICE_PATH_SUBTYPE =	(0x04),
	FWTS_UEFI_PROTOCOL_DEVICE_PATH_SUBTYPE =	(0x05)
} media_dev_path_subtypes;

typedef enum {
	FWTS_UEFI_BIOS_DEVICE_PATH_SUBTYPE = 		(0x01)
} bios_dev_path_subtypes;

typedef struct {
	uint32_t info1;
	uint16_t info2;
	uint16_t info3;
	uint8_t  info4[8];
} __attribute__ ((aligned(8))) fwts_uefi_guid;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint8_t function;
	uint8_t device;
} __attribute__ ((packed)) fwts_uefi_pci_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint8_t function;
} __attribute__ ((packed)) fwts_uefi_pccard_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t memory_type;
	uint64_t start_addr;
	uint64_t end_addr;
} __attribute__ ((packed)) fwts_uefi_mem_mapped_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	fwts_uefi_guid	guid;
	uint8_t	data[0];
} __attribute__ ((packed)) fwts_uefi_vendor_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t controller;
} __attribute__ ((packed)) fwts_uefi_controller_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t hid;
	uint32_t uid;
} fwts_uefi_acpi_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t hid;
	uint32_t uid;
	uint32_t cid;
	char hidstr[1];
} fwts_uefi_expanded_acpi_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint8_t primary_secondary;
	uint8_t slave_master;
	uint16_t lun;
} fwts_uefi_atapi_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint16_t pun;
	uint16_t lun;
} fwts_uefi_scsi_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t reserved;
	uint64_t wwn;
	uint64_t lun;
} fwts_uefi_fibre_channel_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t reserved;
	uint64_t guid;
} fwts_uefi_1394_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint8_t parent_port_number;
	uint8_t interface;
} fwts_uefi_usb_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint16_t vendor_id;
	uint16_t product_id;
	uint8_t device_class;
	uint8_t device_subclass;
	uint8_t device_protocol;
} fwts_uefi_usb_class_dev_path;

typedef struct
{
	fwts_uefi_dev_path dev_path;
	uint32_t tid;
} fwts_uefi_i2o_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
  	fwts_uefi_mac_addr mac_addr;
	uint8_t if_type;
} fwts_uefi_mac_addr_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
  	fwts_uefi_ipv4_addr local_ip_addr;
  	fwts_uefi_ipv4_addr remote_ip_addr;
  	uint16_t local_port;
  	uint16_t remote_port;
  	uint16_t protocol;
  	uint8_t static_ip_address;
} fwts_uefi_ipv4_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
  	fwts_uefi_ipv6_addr local_ip_addr;
  	fwts_uefi_ipv6_addr remote_ip_addr;
  	uint16_t local_port;
  	uint16_t remote_port;
  	uint16_t protocol;
  	uint8_t static_ip_address;
} fwts_uefi_ipv6_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t resource_flags;
	uint8_t port_gid[16];
	uint64_t remote_id;
	uint64_t target_port_id;
	uint64_t device_id;
} fwts_uefi_infiniband_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t reserved;
	uint64_t baud_rate;
	uint8_t data_bits;
	uint8_t parity;
	uint8_t stop_bits;
} fwts_uefi_uart_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	fwts_uefi_guid guid;
	uint8_t vendor_defined_data[0];
} fwts_uefi_vendor_messaging_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t partition_number;
	uint64_t partition_start;
	uint64_t partition_size;
	uint8_t partition_signature[8];
	uint8_t mbr_type;
	uint8_t signature_type;
} fwts_uefi_hard_drive_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint32_t boot_entry;
	uint64_t partition_start;
	uint64_t partition_size;
} fwts_uefi_cdrom_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	fwts_uefi_guid guid;
	uint8_t vendor_defined_data[0];
} fwts_uefi_vendor_media_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint16_t path_name[0];
} fwts_uefi_file_path_dev_path;

typedef struct {
	fwts_uefi_dev_path dev_path;
	uint16_t device_type;
	uint16_t status_flags;
  	char description[0];
} fwts_uefi_bios_dev_path;

void fwts_uefi_str16_to_str(char *dst, const size_t len, const uint16_t *src);
size_t fwts_uefi_str16len(const uint16_t *str);
void fwts_uefi_get_varname(char *varname, const size_t len, const fwts_uefi_var *var);
int fwts_uefi_get_variable(const char *varname, fwts_uefi_var *var);
int fwts_uefi_set_variable(const char *varname, fwts_uefi_var *var);

#endif
