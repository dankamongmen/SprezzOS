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

#include <dirent.h>

#include "fwts.h"
#include "fwts_uefi.h"

typedef void (*uefidump_func)(fwts_framework *fw, fwts_uefi_var *var);

typedef struct {
	char *description;		/* UEFI var */
	uefidump_func	func;		/* Function to dump this variable */
} uefidump_info;

static char *uefidump_vprintf(char *str, const char *fmt, ...) __attribute__((format(printf, 2, 3)));

/*
 *  uefidump_vprintf()
 *	printf() to str: if str NULL - allocate buffer and print into it,
 *	otherwise allocate more space and append new text to end of existing
 *	string.  Return new string, or NULL if failed.
 */
static char *uefidump_vprintf(char *str, const char *fmt, ...)
{
	va_list args;
	char buffer[4096];

	va_start(args, fmt);

	vsnprintf(buffer, sizeof(buffer), fmt, args);

	if (str == NULL)
		str = strdup(buffer);
	else {
		str = realloc(str, strlen(str) + strlen(buffer) + 1);
		if (str == NULL)
			return NULL;
		strcat(str, buffer);
	}

	va_end(args);
	return str;
}

/*
 *  uefidump_build_dev_path()
 *	recursively scan dev_path and build up a human readable path name
 */
static char *uefidump_build_dev_path(char *path, fwts_uefi_dev_path *dev_path)
{
	switch (dev_path->type & 0x7f) {
	case FWTS_UEFI_END_DEV_PATH_TYPE:
		switch (dev_path->subtype) {
		case FWTS_UEFI_END_ENTIRE_DEV_PATH_SUBTYPE:
		case FWTS_UEFI_END_THIS_DEV_PATH_SUBTYPE:
			break;
		default:
			return uefidump_vprintf(path, "\\Unknown-End(0x%x)", (unsigned int) dev_path->subtype);
		}
		break;
	case FWTS_UEFI_HARDWARE_DEV_PATH_TYPE:
		switch (dev_path->subtype) {
		case FWTS_UEFI_PCI_DEV_PATH_SUBTYPE:
			{
				fwts_uefi_pci_dev_path *p = (fwts_uefi_pci_dev_path *)dev_path;
				path = uefidump_vprintf(path, "\\PCI(0x%x,0x%x)",
					(unsigned int)p->function, (unsigned int)p->device);
			}
			break;
		case FWTS_UEFI_PCCARD_DEV_PATH_SUBTYPE:
			{
				fwts_uefi_pccard_dev_path *p = (fwts_uefi_pccard_dev_path *)dev_path;
				path = uefidump_vprintf(path, "\\PCCARD(0x%x)",
					(unsigned int)p->function);
				
			}
			break;
		case FWTS_UEFI_MEMORY_MAPPED_DEV_PATH_SUBTYPE:
			{
				fwts_uefi_mem_mapped_dev_path *m = (fwts_uefi_mem_mapped_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\Memmap(0x%x,0x%llx,0x%llx)",
					(unsigned int)m->memory_type,
					(unsigned long long int)m->start_addr,
					(unsigned long long int)m->end_addr);
			}
			break;
		case FWTS_UEFI_VENDOR_DEV_PATH_SUBTYPE:
			{
				fwts_uefi_vendor_dev_path *v = (fwts_uefi_vendor_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\VENDOR(%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x)",
					v->guid.info1, v->guid.info2, v->guid.info3,
					v->guid.info4[0], v->guid.info4[1], v->guid.info4[2], v->guid.info4[3],
					v->guid.info4[4], v->guid.info4[5], v->guid.info4[6], v->guid.info4[7]);
			}
			break;
		case FWTS_UEFI_CONTROLLER_DEV_PATH_SUBTYPE:
			{
				fwts_uefi_controller_dev_path *c = (fwts_uefi_controller_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\Controller(0x%x)",
					(unsigned int)c->controller);
				
			}
			break;
		default:
			path = uefidump_vprintf(path, "\\Unknown-HW-DEV-PATH(0x%x)", (unsigned int) dev_path->subtype);
			break;
		}
		break;

	case FWTS_UEFI_ACPI_DEVICE_PATH_TYPE:
		switch (dev_path->subtype) {
		case FWTS_UEFI_ACPI_DEVICE_PATH_SUBTYPE: 
			{
				fwts_uefi_acpi_dev_path *a = (fwts_uefi_acpi_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\ACPI(0x%x,0x%x)",
					(unsigned int)a->hid, (unsigned int)a->uid);
				
			}
			break;
		case FWTS_UEFI_EXPANDED_ACPI_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_expanded_acpi_dev_path *a = (fwts_uefi_expanded_acpi_dev_path*)dev_path;
				char *hidstr= a->hidstr;
				path = uefidump_vprintf(path, "\\ACPI(");
				if (hidstr[0] == '\0')
					path = uefidump_vprintf(path, "0x%x,", (unsigned int)a->hid);
				else
					path = uefidump_vprintf(path, "%s,", hidstr);
				hidstr += strlen(hidstr) + 1;
				if (hidstr[0] == '\0')
					path = uefidump_vprintf(path, "0x%x,", (unsigned int)a->uid);
				else
					path = uefidump_vprintf(path, "%s,", hidstr);
				hidstr += strlen(hidstr) + 1;
				if (hidstr[0] == '\0')
					path = uefidump_vprintf(path, "0x%x,", (unsigned int)a->cid);
				else
					path = uefidump_vprintf(path, "%s,", hidstr);
			}
		default:
			path = uefidump_vprintf(path, "\\Unknown-ACPI-DEV-PATH(0x%x)", (unsigned int) dev_path->subtype);
			break;
		}
		break;

	case FWTS_UEFI_MESSAGING_DEVICE_PATH_TYPE:
		switch (dev_path->subtype) {
			case FWTS_UEFI_ATAPI_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_atapi_dev_path *a = (fwts_uefi_atapi_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\ATAPI(0x%x,0x%x,0x%x)",
					(unsigned int)a->primary_secondary, (unsigned int)a->slave_master, (unsigned int)a->lun);
			}
			break;
		case FWTS_UEFI_SCSI_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_scsi_dev_path *s = (fwts_uefi_scsi_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\SCSI(0x%x,0x%x)",
					(unsigned int)s->pun, (unsigned int)s->lun);
			}
			break;
		case FWTS_UEFI_FIBRE_CHANNEL_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_fibre_channel_dev_path *f = (fwts_uefi_fibre_channel_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\FIBRECHANNEL(0x%x,0x%x)",
					(unsigned int)f->wwn, (unsigned int)f->lun);
				
			}
			break;
		case FWTS_UEFI_1394_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_1394_dev_path *fw = (fwts_uefi_1394_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\1394(0x%llx)",
					(unsigned long long int)fw->guid);
			}
			break;
		case FWTS_UEFI_USB_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_usb_dev_path *u = (fwts_uefi_usb_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\USB(0x%x,0x%x)",
					(unsigned int)u->parent_port_number, (unsigned int)u->interface);
			}
			break;
		case FWTS_UEFI_USB_CLASS_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_usb_class_dev_path *u = (fwts_uefi_usb_class_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\USBCLASS(0x%x,0x%x,0x%x,0x%x,0x%x)",
					(unsigned int)u->vendor_id, (unsigned int)u->product_id,
					(unsigned int)u->device_class, (unsigned int)u->device_subclass,
					(unsigned int)u->device_protocol);
			}
			break;
		case FWTS_UEFI_I2O_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_i2o_dev_path *i2o = (fwts_uefi_i2o_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\I2O(0x%x)", (unsigned int)i2o->tid);
					
			}
			break;
		case FWTS_UEFI_MAC_ADDRESS_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_mac_addr_dev_path *m = (fwts_uefi_mac_addr_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\MACADDR(%x:%x:%x:%x:%x:%x,0x%x)",	
					(unsigned int)m->mac_addr[0], (unsigned int)m->mac_addr[1],
					(unsigned int)m->mac_addr[2], (unsigned int)m->mac_addr[3],
					(unsigned int)m->mac_addr[4], (unsigned int)m->mac_addr[5],
					(unsigned int)m->if_type);
			}
			break;
		case FWTS_UEFI_IPV4_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_ipv4_dev_path *i = (fwts_uefi_ipv4_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\%u.%u.%u.%u,%u.%u.%u.%u,%u,%u,%x,%x)",
					(unsigned int)i->local_ip_addr[0], (unsigned int)i->local_ip_addr[1],
					(unsigned int)i->local_ip_addr[2], (unsigned int)i->local_ip_addr[3],
					(unsigned int)i->remote_ip_addr[0], (unsigned int)i->remote_ip_addr[1],
					(unsigned int)i->remote_ip_addr[2], (unsigned int)i->remote_ip_addr[3],
					(unsigned int)i->local_port, (unsigned int)i->remote_port,
					(unsigned int)i->protocol, (unsigned int)i->static_ip_address);
			}
			break;
		case FWTS_UEFI_IPV6_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_ipv6_dev_path *i = (fwts_uefi_ipv6_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\IPv6(%x:%x:%x:%x:%x:%x:%x:%x,%x:%x:%x:%x:%x:%x:%x:%x,%u,%u,%x,%x)",
					(unsigned int)i->local_ip_addr[0], (unsigned int)i->local_ip_addr[1],
					(unsigned int)i->local_ip_addr[2], (unsigned int)i->local_ip_addr[3],
					(unsigned int)i->local_ip_addr[4], (unsigned int)i->local_ip_addr[5],
					(unsigned int)i->local_ip_addr[6], (unsigned int)i->local_ip_addr[7],
					(unsigned int)i->remote_ip_addr[0], (unsigned int)i->remote_ip_addr[1],
					(unsigned int)i->remote_ip_addr[2], (unsigned int)i->remote_ip_addr[3],
					(unsigned int)i->remote_ip_addr[4], (unsigned int)i->remote_ip_addr[5],
					(unsigned int)i->remote_ip_addr[6], (unsigned int)i->remote_ip_addr[7],
					(unsigned int)i->local_port, (unsigned int)i->remote_port,
					(unsigned int)i->protocol, (unsigned int)i->static_ip_address);
			}
			break;
		case FWTS_UEFI_INFINIBAND_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_infiniband_dev_path *i = (fwts_uefi_infiniband_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\InfiniBand(%x,%llx,%llx,%llx)",
					(unsigned int) i->port_gid[0],
					(unsigned long long int)i->remote_id,
					(unsigned long long int)i->target_port_id,
					(unsigned long long int)i->device_id);
			}
			break;
		case FWTS_UEFI_UART_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_uart_dev_path *u = (fwts_uefi_uart_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\UART(%llu baud,%u,%x,%x)",
					(unsigned long long int)u->baud_rate, u->data_bits, u->parity, u->stop_bits);
			}
			break;
		case FWTS_UEFI_VENDOR_MESSAGING_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_vendor_messaging_dev_path *v = (fwts_uefi_vendor_messaging_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\VENDOR(%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x)",
					v->guid.info1, v->guid.info2, v->guid.info3,
					v->guid.info4[0], v->guid.info4[1], v->guid.info4[2], v->guid.info4[3],
					v->guid.info4[4], v->guid.info4[5], v->guid.info4[6], v->guid.info4[7]);
			}
			break;
		default:
			path = uefidump_vprintf(path, "\\Unknown-MESSAGING-DEV-PATH(0x%x)", (unsigned int) dev_path->subtype);
			break;
		}
		break;

	case FWTS_UEFI_MEDIA_DEVICE_PATH_TYPE:
		switch (dev_path->subtype) {
		case FWTS_UEFI_HARD_DRIVE_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_hard_drive_dev_path *h = (fwts_uefi_hard_drive_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\HARDDRIVE(%u,%llx,%llx,%02x%02x%02x%02x%02x%02x%02x%02x,%x,%x)",
				h->partition_number, 
				(unsigned long long int)h->partition_start,
				(unsigned long long int)h->partition_size,
				(unsigned int)h->partition_signature[0], (unsigned int)h->partition_signature[1],
				(unsigned int)h->partition_signature[2], (unsigned int)h->partition_signature[3],
				(unsigned int)h->partition_signature[4], (unsigned int)h->partition_signature[5],
				(unsigned int)h->partition_signature[6], (unsigned int)h->partition_signature[7],
				(unsigned int)h->mbr_type, (unsigned int)h->signature_type);
			}
			break;
		case FWTS_UEFI_CDROM_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_cdrom_dev_path *c = (fwts_uefi_cdrom_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\CDROM(%u,%llx,%llx)",
					c->boot_entry,
					(unsigned long long int)c->partition_start,
					(unsigned long long int)c->partition_size);
			}
			break;
		case FWTS_UEFI_VENDOR_MEDIA_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_vendor_media_dev_path *v = (fwts_uefi_vendor_media_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\VENDOR(%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x)",
					v->guid.info1, v->guid.info2, v->guid.info3,
					v->guid.info4[0], v->guid.info4[1], v->guid.info4[2], v->guid.info4[3],
					v->guid.info4[4], v->guid.info4[5], v->guid.info4[6], v->guid.info4[7]);
			}
			break;
		case FWTS_UEFI_FILE_PATH_DEVICE_PATH_SUBTYPE:
			{	
				char tmp[4096];
				fwts_uefi_file_path_dev_path *f = (fwts_uefi_file_path_dev_path*)dev_path;
				fwts_uefi_str16_to_str(tmp, sizeof(tmp), f->path_name);
				path = uefidump_vprintf(path, "\\FILE('%s')", tmp);
			}
			break;
		case FWTS_UEFI_PROTOCOL_DEVICE_PATH_SUBTYPE:
		default:
			path = uefidump_vprintf(path, "\\Unknown-MEDIA-DEV-PATH(0x%x)", (unsigned int) dev_path->subtype);
			break;
		}
		break;

	case FWTS_UEFI_BIOS_DEVICE_PATH_TYPE:
		switch (dev_path->subtype) {
		case FWTS_UEFI_BIOS_DEVICE_PATH_SUBTYPE:
			{
				fwts_uefi_bios_dev_path *b = (fwts_uefi_bios_dev_path*)dev_path;
				path = uefidump_vprintf(path, "\\BIOS(%x,%x,%s)",
					(unsigned int)b->device_type, (unsigned int)b->status_flags, b->description);
			}
			break;
		default:
			path = uefidump_vprintf(path, "\\Unknown-BIOS-DEV-PATH(0x%x)", (unsigned int) dev_path->subtype);
			break;
		}
		break;
			
	default:
		path = uefidump_vprintf(path, "\\Unknown-TYPE(0x%x)", (unsigned int) dev_path->type);
		break;
	}

	/* Not end? - collect more */
	if (!((dev_path->type & 0x7f) == (FWTS_UEFI_END_DEV_PATH_TYPE) &&
	      (dev_path->subtype == FWTS_UEFI_END_ENTIRE_DEV_PATH_SUBTYPE))) {
		uint16_t len = dev_path->length[0] | (((uint16_t)dev_path->length[1])<<8);
		dev_path = (fwts_uefi_dev_path*)((char *)dev_path + len);
		path = uefidump_build_dev_path(path, dev_path);
	}

	return path;
}

static void uefidump_info_dev_path(fwts_framework *fw, fwts_uefi_var *var)
{
	char *path;

	path = uefidump_build_dev_path(NULL, (fwts_uefi_dev_path*)var->data);

	fwts_log_info_verbatum(fw, "  Device Path: %s.", path);

	free(path);
}

static void uefidump_info_lang(fwts_framework *fw, fwts_uefi_var *var)
{
	uint8_t *data = (uint8_t*)var->data;
	fwts_log_info_verbatum(fw, "  Language: %c%c%c%c.", data[0], data[1], data[2], data[3]);
}

static void uefidump_info_langcodes(fwts_framework *fw, fwts_uefi_var *var)
{
	char buffer[2048];
	char *dst = buffer;
	char *data = (char*)var->data;

	for (;;) {
		*dst++ = *data++;
		*dst++ = *data++;
		*dst++ = *data++;
		if (*data < ' ')
			break;
		*dst++ = ',';
	}
	*dst = '\0';

	fwts_log_info_verbatum(fw, "  Language Codes: %s.", buffer);
}

static void uefidump_info_platform_lang(fwts_framework *fw, fwts_uefi_var *var)
{
	uint8_t *data = (uint8_t*)var->data;
	fwts_log_info_verbatum(fw, "  Platform Language: %c%c%c%c%c%c.", data[0], data[1], data[2], data[3], data[4], data[5]);
}

static void uefidump_info_platform_langcodes(fwts_framework *fw, fwts_uefi_var *var)
{
	char buffer[2048];

	char *dst = buffer;
	char *data = (char*)var->data;

	for (;;) {
		if (*data < ' ')
			break;
		if (*data == ';')
			*dst++ = ',';
		else
			*dst++ = *data;
		data++;
	}
	*dst = '\0';

	fwts_log_info_verbatum(fw, "  Platform Language Codes: %s.", buffer);
}

static void uefidump_info_timeout(fwts_framework *fw, fwts_uefi_var *var)
{
	uint16_t *data = (uint16_t*)var->data;
	fwts_log_info_verbatum(fw, "Timeout: %d seconds.", (int)*data);
}

static void uefidump_info_bootcurrent(fwts_framework *fw, fwts_uefi_var *var)
{
	uint16_t *data = (uint16_t *)var->data;

	fwts_log_info_verbatum(fw, "  BootCurrent: 0x%4.4x.", (unsigned int)*data);
}

static void uefidump_info_bootnext(fwts_framework *fw, fwts_uefi_var *var)
{
	uint16_t *data = (uint16_t *)var->data;

	fwts_log_info_verbatum(fw, "  BootNext: 0x%4.4x.", (unsigned int)*data);
}

static void uefidump_info_bootoptionsupport(fwts_framework *fw, fwts_uefi_var *var)
{
	uint16_t *data = (uint16_t *)var->data;

	fwts_log_info_verbatum(fw, "  BootOptionSupport: 0x%4.4x.", (unsigned int)*data);
}

static void uefidump_info_bootorder(fwts_framework *fw, fwts_uefi_var *var)
{
	uint16_t *data = (uint16_t*)var->data;
	int i;
	int n = (int)var->datalen / sizeof(uint16_t);
	char *str = NULL;

	for (i = 0; i<n; i++) {
		str = uefidump_vprintf(str, "0x%04x%s",
			*data++, i < (n - 1) ? "," : "");
	}
	fwts_log_info_verbatum(fw, "  Boot Order: %s.", str);
}

static void uefidump_info_bootdev(fwts_framework *fw, fwts_uefi_var *var)
{
	fwts_uefi_load_option * load_option = (fwts_uefi_load_option *)var->data;
	char tmp[2048];
	char *path;
	int len;

	fwts_log_info_verbatum(fw, "  Active: %s\n",
		(load_option->attributes & FWTS_UEFI_LOAD_ACTIVE) ? "Yes" : "No");
	fwts_uefi_str16_to_str(tmp, sizeof(tmp), load_option->description);
	len = fwts_uefi_str16len(load_option->description);
	fwts_log_info_verbatum(fw, "  Info: %s\n", tmp);

	/* Skip over description to get to packed path, unpack path and print */
	path = (char *)var->data + sizeof(load_option->attributes) +
		sizeof(load_option->file_path_list_length) + 
		(sizeof(uint16_t) * (len + 1));
	path = uefidump_build_dev_path(NULL, (fwts_uefi_dev_path *)path);
	fwts_log_info_verbatum(fw, "  Path: %s.", path);
	free(path);
}

static uefidump_info uefidump_info_table[] = {
	{ "PlatformLangCodes",	uefidump_info_platform_langcodes },
	{ "PlatformLang",	uefidump_info_platform_lang },
	{ "BootOptionSupport", 	uefidump_info_bootoptionsupport },
	{ "BootCurrent", 	uefidump_info_bootcurrent },
	{ "BootOrder",		uefidump_info_bootorder },
	{ "BootNext", 		uefidump_info_bootnext },
	{ "ConInDev",		uefidump_info_dev_path },
	{ "ConIn",		uefidump_info_dev_path },
	{ "ConOutDev",		uefidump_info_dev_path },
	{ "ConOut",		uefidump_info_dev_path },
	{ "ErrOutDev",		uefidump_info_dev_path },
	{ "ErrOut",		uefidump_info_dev_path },
	{ "LangCodes",		uefidump_info_langcodes },
	{ "Lang",		uefidump_info_lang },
	{ "Timeout",		uefidump_info_timeout },
	{ "Boot0",		uefidump_info_bootdev },
	{ NULL, NULL }
};

static int uefidump_true_filter(const struct dirent *d)
{
	return 1;
}

/*
 *  uefidump_attribute()
 *	convert attribute into a human readable form
 */
static char *uefidump_attribute(uint32_t attr)
{
	static char str[50];

	*str = 0;

	if (attr & FWTS_UEFI_VAR_NON_VOLATILE)
		strcat(str, "NonVolatile");

	if (attr & FWTS_UEFI_VAR_BOOTSERVICE_ACCESS) {
		if (*str) 
			strcat(str, ",");
		strcat(str, "BootServ");
	}
	
	if (attr & FWTS_UEFI_VAR_RUNTIME_ACCESS) {
		if (*str) 
			strcat(str, ",");
		strcat(str, "RunTime");
	}

	return str;
}

static void uefidump_var(fwts_framework *fw, fwts_uefi_var *var)
{
	char varname[512];
	char guid_str[37];
	uefidump_info *info;
	int i;
	uint8_t *data;

	fwts_uefi_get_varname(varname, sizeof(varname), var);

	fwts_log_info_verbatum(fw, "Name: %s.", varname);
	fwts_guid_buf_to_str(var->guid, guid_str, sizeof(guid_str));
	fwts_log_info_verbatum(fw, "  GUID: %s", guid_str);
	fwts_log_info_verbatum(fw, "  Attr: 0x%x (%s).", var->attributes, uefidump_attribute(var->attributes));

	/* If we've got an appropriate per variable dump mechanism, use this */
	for (info = uefidump_info_table; info->description != NULL; info++) {
		if (strncmp(varname, info->description, strlen(info->description)) == 0) {
			info->func(fw, var);
			return;
		}
	}

	/* otherwise just do a plain old hex dump */
	fwts_log_info_verbatum(fw,  "  Size: %d bytes of data.", (int)var->datalen);
	data = (uint8_t*)&var->data;

	for (i=0; i<(int)var->datalen; i+= 16) {
		char buffer[128];
		int left = (int)var->datalen - i;

		fwts_dump_raw_data(buffer, sizeof(buffer), data + i, i, left > 16 ? 16 : left);
		fwts_log_info_verbatum(fw,  "  Data: %s", buffer+2);
	}
}

static int uefidump_init(fwts_framework *fw)
{
	if (fwts_firmware_detect() != FWTS_FIRMWARE_UEFI) {
		fwts_log_info(fw, "Cannot detect any UEFI firmware. Aborted.");
		return FWTS_ABORTED;
	}

	return FWTS_OK;
}

static int uefidump_test1(fwts_framework *fw)
{
	int n;
	int i;
	struct dirent **names = NULL;

	n = scandir("/sys/firmware/efi/vars", &names, uefidump_true_filter, alphasort);
	if (n <= 0) {
		fwts_log_info(fw, "Cannot find any UEFI variables.");
	} else {
		for (i=0; i<n; i++) {
			fwts_uefi_var var;
			if ((names[i] != NULL) && 
		    	(fwts_uefi_get_variable(names[i]->d_name, &var) == FWTS_OK)) {
				uefidump_var(fw, &var);
				fwts_log_nl(fw);
			}
			free(names[i]);
		}
	}
	free(names);

	return FWTS_OK;
}

static fwts_framework_minor_test uefidump_tests[] = {
	{ uefidump_test1, "Dump UEFI Variables." },
	{ NULL, NULL }
};

static fwts_framework_ops uefidump_ops = {
	.description = "Dump UEFI variables.",
	.init        = uefidump_init,
	.minor_tests = uefidump_tests
};

FWTS_REGISTER(uefidump, &uefidump_ops, FWTS_TEST_ANYTIME, FWTS_UTILS | FWTS_ROOT_PRIV);
