#!/bin/bash
ZSST_PLUGIN_NAME="Disable Z-Ray and URL Insight"


if [ $NONSU ]; then
	echo "You need to be superuser to perform this operation."
	exit 1
fi

. $ZCE_PREFIX/share/support_tool/st_funcs.lib

INI_FILE="$ZCE_PREFIX/etc/statistics.ini"

if [ "$2" = "--revert" ]; then
	sed -i "s@; \[ST --zray-off\] zend_extension_manager\.dir\.statistics@zend_extension_manager.dir.statistics@g" $INI_FILE
else
	sed -i "s@zend_extension_manager\.dir\.statistics@; [ST --zray-off] zend_extension_manager.dir.statistics@g" $INI_FILE
fi

yesnocommand "Confirm restart of Zend Server" "Zend Server needs to be restarted to apply the changes." "$ZCE_PREFIX/bin/zendctl.sh restart"
