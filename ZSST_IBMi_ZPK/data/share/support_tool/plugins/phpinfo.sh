#!/usr/bin/ksh
true
#shellcheck disable=SC2034
ZSST_PLUGIN_NAME="HTML phpinfo Collector"
exec >> $ZEND_ERROR_LOG 2>&1

enginePort=$(grep 'zend_gui.enginePort' $ZCE_PREFIX/gui/config/zs_ui.ini | cut -d'=' -f2 | tr -d '[:space:]')

cat <<EOST > /tmp/zs_php_info.php
<?php
\$fileUrl = 'http://127.0.0.1:$enginePort/UserServer/zsd_php_info.php';
\$saveTo = '/tmp/phpinfo_main.html';
\$fp = fopen(\$saveTo, 'w+');
\$ch = curl_init(\$fileUrl);
curl_setopt(\$ch, CURLOPT_FILE, \$fp);
curl_setopt(\$ch, CURLOPT_TIMEOUT, 20);
curl_exec(\$ch);
curl_close(\$ch);
EOST

$ZCE_PREFIX/bin/php -f /tmp/zs_php_info.php
$ZCE_PREFIX/bin/php -nr "\$info=json_decode(file_get_contents('/tmp/phpinfo_main.html'), true); echo \$info['phpinfo'];" > $ZEND_DATA_TMPDIR/real_phpinfo_main.html
rm -f /tmp/zs_php_info.php
rm -f /tmp/phpinfo_main.html
mv $ZEND_DATA_TMPDIR/real_phpinfo_main.html $ZEND_DATA_TMPDIR/phpinfo_main.html
