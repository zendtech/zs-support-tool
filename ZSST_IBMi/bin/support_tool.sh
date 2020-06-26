#!/usr/bin/ksh

if [ -z "$ST_ROOT" ]; then
    # not running from ZPK
    cd "$(dirname $0)/.." || exit 1
    ZS_PATH=$(pwd)
    WEB_SRV_DIR=/www/$(basename $ZS_PATH)
fi

#shellcheck source=/usr/local/zendphp7/etc/zce.rc
. $ZS_PATH/etc/zce.rc
export ZCE_PREFIX

#set PATH
PATH=$PATH:/usr/sbin:/usr/bin:$ZCE_PREFIX/bin

#set temporary directory
if [ -z "$TMPDIR" ];then
    TMPDIR=/tmp
fi

if [ -z "$ST_ROOT" ]; then
    ST_ROOT="$ZCE_PREFIX"
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

for PLUGIN in $ST_ROOT/share/support_tool/plugins/*.sh; do
	export "$(grep 'ZSST_PLUGIN_NAME=' $PLUGIN | head -1)"
    echo "   Start $ZSST_PLUGIN_NAME" | tee -a "$ZEND_ERROR_LOG"
	$PLUGIN
    echo "   End   $ZSST_PLUGIN_NAME" | tee -a "$ZEND_ERROR_LOG"
done
# ZSST plugins end

cd $TMPDIR || exit 1
tar cf ${ZEND_COMPRESSED_REPORT} ${ZEND_DATA_DIR}
${ZCE_PREFIX}/bin/gzip -9 ${ZEND_COMPRESSED_REPORT}

if [ -n "$ZPK_DOCROOT" ]; then
    mv ${ZEND_COMPRESSED_REPORT}.gz "$ZPK_DOCROOT/"
    ARCHIVE_PATH="${ZEND_COMPRESSED_REPORT}.gz"
else
    ARCHIVE_PATH="$TMPDIR/${ZEND_COMPRESSED_REPORT}.gz"
fi

if [ $? -eq 0 ];then
    rm -rf $ZEND_DATA_TMPDIR
    echo
    echo "Archive successfully created:"
    echo "    $ARCHIVE_PATH"
else
    echo "Could not create the archive, leaving"
    echo "    $ZEND_DATA_TMPDIR"
    echo "behind for you to archive manually."
fi
