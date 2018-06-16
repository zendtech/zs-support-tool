#!/bin/bash
ZSST_PLUGIN_NAME="HTML phpinfo() Collector"
exec >> $ZEND_ERROR_LOG 2>&1


. $ZCE_PREFIX/share/support_tool/st_funcs.lib


# TODO - Config parsing to handle custom ports and GUI SSL port


downloadtofile "http://127.0.0.1:10083/zsd_php_info.php" "$ZEND_DATA_TMPDIR/phpinfo_main.html"
$ZCE_PREFIX/bin/php -nr "\$info=json_decode(file_get_contents('$ZEND_DATA_TMPDIR/phpinfo_main.html'), true); echo \$info['phpinfo'];" > $ZEND_DATA_TMPDIR/real_phpinfo_main.html
rm $ZEND_DATA_TMPDIR/phpinfo_main.html
mv $ZEND_DATA_TMPDIR/real_phpinfo_main.html $ZEND_DATA_TMPDIR/phpinfo_main.html


if [ !$NONSU ]; then
	echo "<?php phpinfo() ?>" > $ZCE_PREFIX/gui/public/info.php
	downloadtofile "http://127.0.0.1:10081/ZendServer/info.php" "$ZEND_DATA_TMPDIR/phpinfo_gui.html"
	rm $ZCE_PREFIX/gui/public/info.php
fi

