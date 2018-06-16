#!/usr/bin/ksh

cd "$(dirname $0)/.." || exit 1
ZS_PATH=$(pwd)
WEB_SRV_DIR=/www/$(basename $ZS_PATH)

#shellcheck source=/usr/local/zendphp7/etc/zce.rc
. $ZS_PATH/etc/zce.rc
export ZCE_PREFIX

#shell_functions.rc check
if [ -f $ZCE_PREFIX/bin/shell_functions.rc ];then
    #shellcheck source=/usr/local/zendphp7/bin/shell_functions.rc
    . $ZCE_PREFIX/bin/shell_functions.rc
else
    echo "$ZCE_PREFIX/bin/shell_functions.rc doesn't exist!"
    exit 1;
fi

#set PATH
PATH=$PATH:$ZCE_PREFIX/bin

#set temporary directory
if [ -z "$TMPDIR" ];then
    TMPDIR=/tmp
fi

#set name of the ST archive
STAMP=`date +%F-%H%M%S`
ZEND_DATA_DIR=ZSST_${STAMP}
ZEND_DATA_TMPDIR=${TMPDIR}/${ZEND_DATA_DIR}
ZEND_ERROR_LOG=${ZEND_DATA_TMPDIR}/support_tool_error.log
ZEND_COMPRESSED_REPORT=ZSST_${PRODUCT_VERSION}_${STAMP}.tar

export ZEND_DATA_DIR
export ZEND_DATA_TMPDIR
export ZEND_ERROR_LOG
export WEB_SRV_DIR

mkdir -p $ZEND_DATA_TMPDIR
cd $ZEND_DATA_TMPDIR || exit 1

# ZSST plugins start
echo "Plugins :"

for PLUGIN in ${ZCE_PREFIX}/share/support_tool/plugins/*.sh; do
	export "$(grep 'ZSST_PLUGIN_NAME=' $PLUGIN | head -1)"
    echo "Start $ZSST_PLUGIN_NAME" >> $ZEND_ERROR_LOG
	$PLUGIN
    echo "End   $ZSST_PLUGIN_NAME" >> $ZEND_ERROR_LOG
	echo " $ZSST_PLUGIN_NAME"
done
# ZSST plugins end

cd $TMPDIR || exit 1
tar cf ${ZEND_COMPRESSED_REPORT} ${ZEND_DATA_DIR}
${ZCE_PREFIX}/bin/gzip -9 ${ZEND_COMPRESSED_REPORT}
if [ $? -eq 0 ];then
    rm -rf $ZEND_DATA_TMPDIR
    echo "Archive successfully created at $TMPDIR/${ZEND_COMPRESSED_REPORT}.gz"
else
    echo "Could not create the archive, leaving $ZEND_DATA_TMPDIR behind for you to archive manually."
fi
