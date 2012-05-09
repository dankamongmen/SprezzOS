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

#include <unistd.h>
#include <stdlib.h>

#include "fwts.h"

/*
 *  fwts_dump_raw_data()
 *	print raw uint8 data of length `nbytes` into a buffer (length len) as a hex dump. nbytes must
 *	be no more than 16. The address/offset of the buffer in memory is annotated by addr.
 */
void fwts_dump_raw_data(char *buffer, const int len, const uint8_t *data, const int addr, const int nbytes)
{
        int i;
	int n = 0;

	n = snprintf(buffer, len, "  %4.4x: ", addr);

	/* Hex dump */
        for (i=0;i<nbytes;i++)
                n += snprintf(buffer + n, len - n, "%2.2x ", data[i]);

	/* Padding */
        for (;i<16;i++)
                n += snprintf(buffer + n, len - n, "   ");

        n += snprintf(buffer + n, len - n, " ");

	/* printable ASCII dump */
        for (i=0;i<nbytes;i++)
		buffer[n++] = (data[i] < 32 || data[i] > 126) ? '.' : data[i];
	buffer[n] = '\0';
}
