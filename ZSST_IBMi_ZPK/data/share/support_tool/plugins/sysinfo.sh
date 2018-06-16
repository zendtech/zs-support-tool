#!/usr/bin/ksh
true
#shellcheck disable=SC2034
ZSST_PLUGIN_NAME="System Information Collector"
exec >> $ZEND_ERROR_LOG 2>&1


while read command; do
	echo "   running $command" >> $ZEND_ERROR_LOG
	#shellcheck disable=SC2046
	# SC2046 - avoiding complicated quoting, also, cut makes sure we don't get spaces in names
	$command >> $ZEND_DATA_TMPDIR/system_$(echo "$command" | cut -d " " -f 1).txt
done <<EOCMD
ipcs -a
ps -ef
df
locale
ulimit
env
EOCMD

# System's Java path for JavaBridge issues
if which java > /dev/null 2>&1 ; then
	which java > $ZEND_DATA_TMPDIR/system_java.txt
fi

echo "   getting qccsid and qchrid" >> $ZEND_ERROR_LOG
system 'dspsysval qccsid' > $ZEND_DATA_TMPDIR/ccsid.txt
system 'dspsysval qchrid' > $ZEND_DATA_TMPDIR/qchrid.txt

# Zend Server semaphore IDs
grep . $ZCE_PREFIX/tmp/*_semid > $ZEND_DATA_TMPDIR/system_ipcs.txt
