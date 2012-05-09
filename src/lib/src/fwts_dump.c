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
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <time.h>
#include <sys/klog.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "fwts.h"

/*
 *  Utilities for the fwts --dump option
 */


/*
 *  dump_data()
 *	dump to path/filename a chunk of data of length len
 */
static int dump_data(const char *path, const char *filename, char *data, const size_t len)
{
	FILE *fp;
	char name[PATH_MAX];

	snprintf(name, sizeof(name), "%s/%s", path, filename);
	if ((fp = fopen(name, "w")) == NULL)
		return FWTS_ERROR;

	if ((fwrite(data, sizeof(char), len, fp) != len)) {
		fclose(fp);
		return FWTS_ERROR;
	}

	fclose(fp);
	return FWTS_OK;
}

/*
 *  dump_dmesg()
 *	read kernel log, dump to path/filename
 */
static int dump_dmesg(const char *path, const char *filename)
{
	int len;
	char *data;
	int ret;

	if ((len = klogctl(10, NULL, 0)) < 0)
		return FWTS_ERROR;

        if ((data = calloc(1, len)) == NULL)
		return FWTS_ERROR;

        if (klogctl(3, data, len) < 0) {
		free(data);
		return FWTS_ERROR;
	}
	ret = dump_data(path, filename, data, strlen(data));

	free(data);

	return ret;
}


/*
 *  dump_exec()
 *  	Execute command, dump output to path/filename
 */
static int dump_exec(const char *path, const char *filename, const char *command)
{
	int fd;
	pid_t pid;
	ssize_t len;
	char *data;
	int ret;

	if ((fd = fwts_pipe_open(command, &pid)) < 0)
		return FWTS_ERROR;

	if ((data = fwts_pipe_read(fd, &len)) == NULL) {
		fwts_pipe_close(fd, pid);
		return FWTS_ERROR;
	}

	fwts_pipe_close(fd, pid);
	
	ret = dump_data(path, filename, data, len);

	free(data);

	return ret;
}

#ifdef FWTS_ARCH_INTEL
/*
 *  dump_dmidecode()
 *	run dmidecode, dump output to path/filename
 */
static int dump_dmidecode(fwts_framework *fw, const char *path, const char *filename)
{
	return dump_exec(path, filename, FWTS_DMIDECODE_PATH);
}
#endif

/*
 *  dump_lspci()
 *	run lspci, dump output to path/filename
 */
static int dump_lspci(fwts_framework *fw, const char *path, const char *filename)
{
	char command[1024];
	
	snprintf(command, sizeof(command), "%s -vv -nn", fw->lspci);

	return dump_exec(path, filename, command);
}

#ifdef FWTS_ARCH_INTEL
/*
 *  dump_acpi_table()
 *	hex dump of a ACPI table
 */
static int dump_acpi_table(fwts_acpi_table_info *table, FILE *fp)
{
	char buffer[128];
	int n;

	fprintf(fp, "%s @ 0x%x\n", table->name, (uint32_t)table->addr);

	for (n = 0; n < table->length; n+=16) {
		int left = table->length - n;
		fwts_dump_raw_data(buffer, sizeof(buffer), table->data + n, n, left > 16 ? 16 : left);
		fprintf(fp, "%s\n", buffer);
	}
	fprintf(fp, "\n");

	return FWTS_OK;
}

/*
 *  dump_acpi_tables()
 *	hex dump all ACPI tables
 */
static int dump_acpi_tables(fwts_framework *fw, const char *path)
{
	char filename[PATH_MAX];
	FILE *fp;
	int i;

	snprintf(filename, sizeof(filename), "%s/acpidump.log", path);
	if ((fp = fopen(filename, "w")) == NULL)
		return FWTS_ERROR;

	for (i=0;;i++) {
		fwts_acpi_table_info *table;

		if (fwts_acpi_get_table(fw, i, &table) == FWTS_ERROR) {
			fprintf(stderr, "Cannot read ACPI tables.\n");
			fclose(fp);
			return FWTS_ERROR;
		}
		if (table == NULL)
			break;

		dump_acpi_table(table, fp);
	}
	fclose(fp);
		
	return FWTS_OK;
}
#endif

/*
 *  dump_readme()
 *	dump README file containing some system info
 */
static int dump_readme(const char *path)
{
	char filename[PATH_MAX];
	time_t now = time(NULL);
	struct tm *tm = localtime(&now);
	FILE *fp;
	char *str;
	int len;

	snprintf(filename, sizeof(filename), "%s/README.txt", path);

	if ((fp = fopen(filename, "w")) == NULL)
		return FWTS_ERROR;

	str = asctime(tm);
	len = strlen(str) - 1;
	fprintf(fp, "This is output captured by fwts on %*.*s.\n\n", len, len, str);

	fwts_framework_show_version(fp, "fwts");

	if ((str = fwts_get("/proc/version")) != NULL) {
		fprintf(fp, "Version: %s", str);
		free(str);
	}

	if ((str = fwts_get("/proc/version_signature")) != NULL) {
		fprintf(fp, "Signature: %s", str);
		free(str);
	}

	fclose(fp);
	
	return FWTS_OK;
}

/*
 *  fwts_dump_info()
 *	dump various system specific information:
 *	kernel log, dmidecode output, lspci output,
 *	ACPI tables
 */
int fwts_dump_info(fwts_framework *fw, const char *path)
{
#ifdef FWTS_ARCH_INTEL
	bool root_priv = (fwts_check_root_euid(fw, false) == FWTS_OK);
#endif

	if (path == NULL)
		path = "./";

	if (access(path, F_OK) != 0)
		mkdir(path, 0777);
	

	if (dump_readme(path) != FWTS_OK)
		fprintf(stderr, "Failed to dump README.txt.\n");
	else
		printf("Created README.txt\n");

	if (dump_dmesg(path, "dmesg.log") != FWTS_OK)
		fprintf(stderr, "Failed to dump kernel log.\n");
	else
		printf("Dumping dmesg to dmesg.log\n");

#ifdef FWTS_ARCH_INTEL
	if (root_priv) {
		if (dump_dmidecode(fw, path, "dmidecode.log") != FWTS_OK)
			fprintf(stderr, "Failed to dump output from dmidecode.\n");
		else
			printf("Dumped DMI data to dmidecode.log\n");
	} else 
		fprintf(stderr, "Need root privilege to dump DMI tables.\n");
#endif

	if (dump_lspci(fw, path, "lspci.log") != FWTS_OK)
		fprintf(stderr, "Failed to dump output from lspci.\n");
	else
		printf("Dumped lspci data to lspci.log\n");

#ifdef FWTS_ARCH_INTEL
	if (root_priv) {
		if (dump_acpi_tables(fw, path) != FWTS_OK)
			fprintf(stderr, "Failed to dump ACPI tables.\n");
		else
			printf("Dumped ACPI tables to acpidump.log\n");
	} else
		fprintf(stderr, "Need root privilege to dump ACPI tables.\n");
#endif

	return FWTS_OK;
}
