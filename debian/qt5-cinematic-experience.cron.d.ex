#
# Regular cron jobs for the qt5-cinematic-experience package
#
0 4	* * *	root	[ -x /usr/bin/qt5-cinematic-experience_maintenance ] && /usr/bin/qt5-cinematic-experience_maintenance
