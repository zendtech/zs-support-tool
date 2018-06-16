#!/bin/bash
ZSST_PLUGIN_NAME="Clean Zend Server Notifications"

# Databases are not accessible for a regular user
if [ ! $NONSU ]; then

. $ZCE_PREFIX/share/support_tool/db_params.lib

	if [ "$dbtype" == "SQLITE" ]; then
		sqlite3  "$ZCE_PREFIX/var/db/zsd.db" "DELETE FROM zsd_notifications;"
	elif [ "$dbtype" == "MYSQL" ]; then
		if which mysql > /dev/null 2>&1 ;then
			$MYSQL_EXEC "DELETE FROM ZSD_NOTIFICATIONS;"
		else
			echo  "This script requires the command-line 'mysql' client. Exiting..."
			exit 1
		fi
	else
		echo  "Could not determine the database type. Exiting..."
		exit 1
	fi
fi
