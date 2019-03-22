#!/bin/bash
ZSST_PLUGIN_NAME="Clean Zend Server Notifications"

# Databases are not accessible for a regular user
if [ ! $NONSU ]; then

. $ZCE_PREFIX/share/support_tool/db_params.lib

	if [ "$dbtype" == "SQLITE" ]; then
		sqlite3  "$ZCE_PREFIX/var/db/zsd.db" "DELETE FROM ZSD_NOTIFICATIONS;"
		sqlite3  "$ZCE_PREFIX/var/db/zsd.db" "DELETE FROM ZSD_MESSAGES;"
	elif [ "$dbtype" == "MYSQL" ]; then
		if command -v mysql > /dev/null 2>&1 ;then
			$MYSQL_EXEC "DELETE FROM ZSD_NOTIFICATIONS;"
			$MYSQL_EXEC "DELETE FROM ZSD_MESSAGES;"
		else
			echo  "This script requires the command-line 'mysql' client. Exiting..."
			exit 1
		fi
	else
		echo  "Could not determine the database type. Exiting..."
		exit 1
	fi
fi
