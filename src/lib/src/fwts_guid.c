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
#include <stdlib.h>
#include <stdint.h>

#include "fwts.h"

void fwts_guid_buf_to_str(uint8_t *guid, char *guid_str, size_t guid_str_len)
{
	if (guid_str && guid_str_len > 36) 
        	snprintf(guid_str, guid_str_len, "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
			guid[3], guid[2], guid[1], guid[0], guid[5], guid[4], guid[7], guid[6],
			guid[8], guid[9], guid[10], guid[11], guid[12], guid[13], guid[14], guid[15]);
}
