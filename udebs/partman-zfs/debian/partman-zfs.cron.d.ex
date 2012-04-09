#
# Regular cron jobs for the partman-zfs package
#
0 4	* * *	root	[ -x /usr/bin/partman-zfs_maintenance ] && /usr/bin/partman-zfs_maintenance
