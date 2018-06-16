#!/bin/bash
ZSST_PLUGIN_NAME="System Overview"
exec >> $ZEND_ERROR_LOG 2>&1


WRITETO=$ZEND_DATA_TMPDIR/overview.txt

sw_vers > $WRITETO
echo >> $WRITETO
uname -a >> $WRITETO
echo >> $WRITETO
$ZCE_PREFIX/bin/php -v >> $WRITETO
echo >> $WRITETO
hostname >> $WRITETO
