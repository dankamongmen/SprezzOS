#
# Regular cron jobs for the spl package
#
0 4	* * *	root	[ -x /usr/bin/spl_maintenance ] && /usr/bin/spl_maintenance
