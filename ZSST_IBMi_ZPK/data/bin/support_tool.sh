#!/usr/bin/ksh

echo "Running Zend Server Support Tool" > ../docroot/status.php
echo >> ../docroot/status.php

THIS_PATH="$(pwd)"
THIS_DIR="$(dirname $THIS_PATH)"
ZS_PATH=$1
WEB_SRV_DIR=$2

#exec >> $THIS_DIR/docroot/status.php 2>&1

#shellcheck source=/usr/local/zendphp7/etc/zce.rc
. $ZS_PATH/etc/zce.rc
export ZCE_PREFIX
PATH=$PATH:/usr/sbin:/usr/bin:$ZCE_PREFIX/bin

#shell_functions.rc check
if [ -f ../bin/shell_functions.rc ];then
    #shellcheck source=/usr/local/zendphp7/bin/shell_functions.rc
    . ../bin/shell_functions.rc
else
    echo "  Error: shell_functions.rc doesn't exist!" >> $THIS_DIR/docroot/status.php
    echo "Support Tool execution completed" >> $THIS_DIR/docroot/status.php
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
echo "   Plugins :" >> $THIS_DIR/docroot/status.php

for PLUGIN in $THIS_DIR/share/support_tool/plugins/*.sh; do
	export "$(grep 'ZSST_PLUGIN_NAME=' $PLUGIN | head -1)"
    echo "     Start $ZSST_PLUGIN_NAME"  >> $THIS_DIR/docroot/status.php
	$PLUGIN
    echo "     End   $ZSST_PLUGIN_NAME"  >> $THIS_DIR/docroot/status.php
done
# ZSST plugins end

cd $TMPDIR || exit 1
tar cf ${ZEND_COMPRESSED_REPORT} ${ZEND_DATA_DIR}
$ZCE_PREFIX/bin/gzip -9 ${ZEND_COMPRESSED_REPORT}
mv ${ZEND_COMPRESSED_REPORT}.gz "$THIS_PATH/"
if [ $? -eq 0 ];then
    rm -rf $ZEND_DATA_TMPDIR
    echo >> $THIS_DIR/docroot/status.php
    echo "Archive successfully created:" >> $THIS_DIR/docroot/status.php
    echo "    ${ZEND_COMPRESSED_REPORT}.gz" >> $THIS_DIR/docroot/status.php
else
    echo "Could not create the archive, leaving" >> $THIS_DIR/docroot/status.php
    echo "  $ZEND_DATA_TMPDIR" >> $THIS_DIR/docroot/status.php
    echo "behind for you to archive manually." >> $THIS_DIR/docroot/status.php
fi

echo >> $THIS_DIR/docroot/status.php
echo "Support Tool execution completed" >> $THIS_DIR/docroot/status.php
