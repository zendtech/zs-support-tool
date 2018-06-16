#!/bin/bash
ZSST_PLUGIN_NAME="Purge Zend Server Monitoring Data"


if [ $NONSU ]; then
	echo "You need to be superuser to perform this operation."
	exit 1
fi

dbtype=$(grep -E '^\s*zend.database.type' $ZCE_PREFIX/etc/zend_database.ini | sed 's@ @@g' | cut -d '=' -f 2)

if [ "$dbtype" != "SQLITE" ]; then
	echo "This server appears to be in a cluster."
	echo "Monitoring data cleanup is currently possible only on stand-alone Zend Server."
	exit 1
fi


. $ZCE_PREFIX/share/support_tool/st_funcs.lib


yesnocommand "Confirm stopping Zend Server" "Zend Server needs to be stopped to continue this operation." "$ZCE_PREFIX/bin/zendctl.sh stop"


rm -f $ZCE_PREFIX/var/db/monitor.db
rm -f $ZCE_PREFIX/var/db/codetracing.db
rm -f $ZCE_PREFIX/var/codetracing/*


echo
echo

yesnocommand "Confirm starting Zend Server" "Zend Server was not started. You need to start it manually." "$ZCE_PREFIX/bin/zendctl.sh start"

