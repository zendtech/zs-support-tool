#!/bin/bash
ZSST_PLUGIN_NAME="Disable Extended Authentication"


if [ $NONSU ]; then
	echo "You need to be superuser to perform this operation."
	exit 1
fi

if [ $# -eq 3  ]; then
	apiName=$2
	apiHash=$3

elif [ $# -eq 1  ]; then
	
	apiName=admin
	. $ZCE_PREFIX/share/support_tool/db_params.lib

	if [ "$dbtype" == "SQLITE" ]; then
		apiHash=$(sqlite3 $ZCE_PREFIX/var/db/gui.db 'SELECT HASH FROM gui_webapi_keys WHERE NAME="admin";')


	elif [ "$dbtype" == "MYSQL" ]; then
		if command -v mysql > /dev/null 2>&1 ;then
			apiHash=$($MYSQL_EXEC 'SELECT HASH FROM GUI_WEBAPI_KEYS WHERE NAME="admin";' -N)
		else
			cat <<EOP
"mysql" command not found.
Please run this command on MySQL server:

$MYSQL_EXEC 'SELECT HASH FROM GUI_WEBAPI_KEYS WHERE NAME="admin";'

This will output the hash - the default 'admin' WebAPI key.

Run Support Tool again with this hash:

./support_tool.sh --simple-auth admin <hash>

EOP
			exit 1
		fi
		
	else
		echo  "Could not determine the database type"
		exit 1
	fi

else
	cat <<EOT

Usage: ./support_tool.sh --simple-auth [apiName apiHash]

EOT
	exit 1
fi

sed -i "s@zend_gui\.simple.*@zend_gui\.simple = 1@" $ZCE_PREFIX/gui/config/zs_ui.ini
sleep 1

$ZCE_PREFIX/bin/zs-manage store-directive -d zend_gui.simple -v 1 -N $apiName -K $apiHash
sleep 3
echo

