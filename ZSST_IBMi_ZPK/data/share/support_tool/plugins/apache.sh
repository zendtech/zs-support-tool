#!/usr/bin/ksh
true
#shellcheck disable=SC2034
ZSST_PLUGIN_NAME="Apache Information Collector"
exec >> $ZEND_ERROR_LOG 2>&1

mkdir ${ZEND_DATA_TMPDIR}/apache_config
mkdir ${ZEND_DATA_TMPDIR}/apache_logs

#Collect Apache conf directory
if [ -d $WEB_SRV_DIR ]; then
	cp -R $WEB_SRV_DIR/conf $ZEND_DATA_TMPDIR/apache_config
else
	echo "Apache configuration not found" >> ${ZEND_ERROR_LOG}
fi

ls -alrtR $WEB_SRV_DIR > $ZEND_DATA_TMPDIR/apache_config/apache_dir.txt

cp $WEB_SRV_DIR/logs/maint.log $ZEND_DATA_TMPDIR/apache_logs

#system "STRTCPSVR SERVER(*HTTP) HTTPSVR(apachedft '-V')" > $ZEND_DATA_TMPDIR/apache_status.txt
cp $ZCE_PREFIX/bin/apache.info $ZEND_DATA_TMPDIR/apache_info.txt

APACHE_LOGDIR_SIZE=`du -sm ${WEB_SRV_DIR}/logs | cut -f1`

if [ ${APACHE_LOGDIR_SIZE} -lt 10 ]; then
	echo "   getting full logs because directory size is   $APACHE_LOGDIR_SIZE MB" >> ${ZEND_ERROR_LOG}
	cp -R ${WEB_SRV_DIR}/logs/* ${ZEND_DATA_TMPDIR}/apache_logs 2>/dev/null
else
	echo "   will trim logs because directory size is   $APACHE_LOGDIR_SIZE MB" >> ${ZEND_ERROR_LOG}
	#shellcheck disable=SC2045
	# SC2045 - need to iterate over ls because sorting by modification time is essential
	for accesslog in $(ls -t ${WEB_SRV_DIR}/logs/access_log.*) ; do
		if [ "$(wc -l $accesslog | tr -d '[:space:]' | cut -d '/' -f 1)" -gt 2000 ]; then
			break
		fi
		echo "\n\n\n----  tail -n2000  ----\n$accesslog :\n" >> ${ZEND_DATA_TMPDIR}/apache_logs/access.log
		# this is just rough limit, but we don't need exactly 2000 lines in the log file
		tail -n2000 $accesslog >> ${ZEND_DATA_TMPDIR}/apache_logs/access.log
	done
	#shellcheck disable=SC2045
	# SC2045 - need to iterate over ls because sorting by modification time is essential
	for errorlog in $(ls -t ${WEB_SRV_DIR}/logs/error_log.*) ; do
		if [ "$(wc -l $errorlog | tr -d '[:space:]' | cut -d '/' -f 1)" -gt 2000 ]; then
			break
		fi
		echo "\n\n\n----  tail -n2000  ----\n$errorlog :\n" >> ${ZEND_DATA_TMPDIR}/apache_logs/error.log
		# this is just rough limit, but we don't need exactly 2000 lines in the log file
		tail -n2000 $errorlog >> ${ZEND_DATA_TMPDIR}/apache_logs/error.log
	done
fi
