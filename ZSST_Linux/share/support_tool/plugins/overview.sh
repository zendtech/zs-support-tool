#!/bin/bash
ZSST_PLUGIN_NAME="System Overview"
exec >> $ZEND_ERROR_LOG 2>&1


WRITETO=$ZEND_DATA_TMPDIR/overview.txt

uname -a > $WRITETO
echo >> $WRITETO
cat /etc/issue >> $WRITETO
echo >> $WRITETO
lsb_release -a >> $WRITETO
echo >> $WRITETO
cat /etc/redhat-release >> $WRITETO
echo >> $WRITETO
cat /etc/os-release >> $WRITETO
echo >> $WRITETO
echo "Web Server: $WEB_SRV" >> $WRITETO
echo >> $WRITETO
$ZCE_PREFIX/bin/php -v >> $WRITETO
echo >> $WRITETO

OrderNr=$(grep 'zend.user_name' $ZCE_PREFIX/etc/ZendGlobalDirectives.ini | cut -d'=' -f2 | tr -d '[:space:]')
LicenseKey=$(grep 'zend.serial_number' $ZCE_PREFIX/etc/ZendGlobalDirectives.ini | cut -d'=' -f2 | tr -d '[:space:]')

cat <<EOST > /tmp/checLic.php
<?php
\$o = "$OrderNr";
\$k = "$LicenseKey";
\$a=zem_serial_number_info(\$k, \$o);

echo "\nOrder #: \$o   ||  License Key: \$k\n\n";
if (\$a['license_ok']) {
    echo "The license is VALID\n------------------------------\n\n";
    switch (\$a['edition']) {
        case 2:
            \$e = 'Production Enterprise';break;
        case 7:
            \$e = 'Production Professional';break;
        case 6:
            \$e = 'Production Small Business';break;
        case 8:
            \$e = 'Developer Enterprise';break;
        case 3:
            \$e = 'Developer Standard';break;
        default:
            \$e = 'NOT RECOGNIZED. May be an incompatible license!!!';break;
    }
    echo "Edition - \$e\n";
    echo "Expires - " . date('j F Y', \$a['expiration_date']) . "\n";
    echo "Servers - {\$a['num_of_nodes']}\n\n";
} else {
    echo "This license is INVALID.\n\n";
    exit(1);
}
EOST

$ZCE_PREFIX/bin/php -f /tmp/checLic.php >> $WRITETO
rm -f /tmp/checLic.php

# These work on Debian only, need universal replacement
#hostname -A >> $WRITETO
#hostname -I >> $WRITETO

hostname -a >> $WRITETO
hostname -d >> $WRITETO
hostname -i >> $WRITETO
