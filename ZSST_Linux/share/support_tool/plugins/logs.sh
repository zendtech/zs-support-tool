#!/bin/bash
ZSST_PLUGIN_NAME="Zend Server Logs Collector"
exec >> $ZEND_ERROR_LOG 2>&1


ZSST_MAIN_LOGS=$ZEND_DATA_TMPDIR/zend_logs
ZSST_GUI_LOGS=$ZEND_DATA_TMPDIR/lighttpd_logs

mkdir $ZSST_MAIN_LOGS
mkdir $ZSST_GUI_LOGS

if [ $FULLLOGS ]; then

	cp -RL $ZCE_PREFIX/var/log/* $ZSST_MAIN_LOGS/
	cp -RL $ZCE_PREFIX/gui/lighttpd/logs/* $ZSST_GUI_LOGS/


else

# Main logs
	fcount=0
	for zslog in $ZCE_PREFIX/var/log/*[a-z].log; do
		if [ -s $zslog ]; then
			tail -n2000 $zslog > $ZSST_MAIN_LOGS/$(basename ${zslog})
			fcount=$(expr $fcount + 1)
		fi
	done

	ls -hAlF $ZCE_PREFIX/var/log/ > $ZSST_MAIN_LOGS/listing.txt
	llines=$(cat $ZSST_MAIN_LOGS/listing.txt | tail -n+2 | wc -l)
	mv $ZSST_MAIN_LOGS/listing.txt "${ZSST_MAIN_LOGS}/${fcount}_of_${llines}.files"


# GUI Logs
	for guilog in $ZCE_PREFIX/gui/lighttpd/logs/*.log; do
		if [ -s $guilog ]; then
			tail -n3000 $guilog > $ZSST_GUI_LOGS/$(basename ${guilog})
		fi
	done


fi


# Installation Logs
tar czf $ZEND_DATA_TMPDIR/zs_install_logs.tgz /tmp/install_zs.*
