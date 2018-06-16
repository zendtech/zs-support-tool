#!/usr/bin/ksh
true
#shellcheck disable=SC2034
ZSST_PLUGIN_NAME="Zend Server Logs Collector"
exec >> $ZEND_ERROR_LOG 2>&1


ZSST_MAIN_LOGS=$ZEND_DATA_TMPDIR/zend_logs

mkdir -p $ZSST_MAIN_LOGS/zs_install_logs
# Main logs
	fcount=0
	for zslog in $ZCE_PREFIX/var/log/*[a-z].log
	do
		if [ -s $zslog ]; then
			tail -n2000 $zslog > "$ZSST_MAIN_LOGS/$(basename ${zslog})"
			fcount=$(expr $fcount + 1)
		fi
	done

	ls -alrtR $ZCE_PREFIX/var/log/ > $ZSST_MAIN_LOGS/listing.txt
	llines=$(cat $ZSST_MAIN_LOGS/listing.txt | wc -l | tr -d '[:space:]')
	mv $ZSST_MAIN_LOGS/listing.txt "${ZSST_MAIN_LOGS}/${fcount}_of_${llines}.files"


# Installation Logs
ls -alrtR /tmp/Zend* > $ZSST_MAIN_LOGS/zs_install_logs/tmp_dir.txt
cp /tmp/ZendServerInstall.* /tmp/ZendDBIInstall.*  $ZSST_MAIN_LOGS/zs_install_logs >>  $ZEND_ERROR_LOG
