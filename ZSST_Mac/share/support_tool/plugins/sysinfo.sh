#!/bin/bash
ZSST_PLUGIN_NAME="System Information"
exec >> $ZEND_ERROR_LOG 2>&1


while read command; do
	$command >> $ZEND_DATA_TMPDIR/system_$(echo "$command" | cut -d " " -f 1).txt
done <<EOCMD
ifconfig
ipcs -a
netstat -an
ps aux
df -h
ipfw -dS list
locale
ulimit -a
EOCMD
