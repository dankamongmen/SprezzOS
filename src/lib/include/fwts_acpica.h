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

#ifndef __FWTS_ACPICA_H__
#define __FWTS_ACPICA_H__

#include "fwts.h"

typedef void (*fwts_acpica_log_callback)(fwts_framework *fw, const char *buffer);

int  fwts_acpica_init(fwts_framework *fw);
int  fwts_acpica_deinit(void);
void fwts_acpica_set_log_callback(fwts_framework *fw, fwts_acpica_log_callback func);
void fwts_acpica_debug_command(fwts_framework *fw, fwts_acpica_log_callback func, char *command);
fwts_list *fwts_acpica_get_object_names(int type);
void fwts_acpica_sem_count_clear(void);
void fwts_acpica_sem_count_get(int *acquired, int *released);
void fwts_acpica_simulate_sem_timeout(int flag);

#endif
