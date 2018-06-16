#!/bin/bash
ZSST_PLUGIN_NAME="Zend Server Database"
exec >> $ZEND_ERROR_LOG 2>&1


# Databases are not accessible for a regular user
if [ ! $NONSU ]; then

. $ZCE_PREFIX/share/support_tool/db_params.lib

	if [ "$dbtype" == "SQLITE" ]; then
		mkdir $ZEND_DATA_TMPDIR/zs_sqlite
		for dbfile in $ZCE_PREFIX/var/db/*.db; do
			echo -n "$dbfile : " >> $ZEND_DATA_TMPDIR/zs_sqlite/integrity.txt
			sqlite3 $dbfile "PRAGMA integrity_check;" >> $ZEND_DATA_TMPDIR/zs_sqlite/integrity.txt
		done
		echo >> $ZEND_DATA_TMPDIR/zs_sqlite/integrity.txt
		ls -hAlF $ZCE_PREFIX/var/db/ >> $ZEND_DATA_TMPDIR/zs_sqlite/integrity.txt
		
		# codetracing.db doesn't have a version record
		while read db table; do
			echo "$db :" >> $ZEND_DATA_TMPDIR/zs_sqlite/schema_ver.txt
			sqlite3 -line $ZCE_PREFIX/var/db/$db "SELECT * from ${table};" >> $ZEND_DATA_TMPDIR/zs_sqlite/schema_ver.txt
			echo >> $ZEND_DATA_TMPDIR/zs_sqlite/schema_ver.txt
		done <<EODBS
deployment.db deployment_properties
gui.db gui_metadata
jobqueue.db version
monitor.db version
statistics.db schema_properties
devbar.db devbar_properties
zsd.db zsd_schema_properties
urlinsight.db urlinsight_properties
EODBS

		if [ $GETSQLITE ]; then
			cp $ZCE_PREFIX/var/db/* $ZEND_DATA_TMPDIR/zs_sqlite/
		fi

	elif [ "$dbtype" == "MYSQL" ]; then
		mkdir $ZEND_DATA_TMPDIR/zs_mysql
		$MYSQL_PHP "$ZEND_DATA_TMPDIR/zs_mysql/mysql_info.html"
	else
		echo  "Could not determine the database type" >> $ZEND_ERROR_LOG
	fi
fi
