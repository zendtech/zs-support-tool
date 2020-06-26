#!/usr/bin/ksh

echo "Running Zend Server Support Tool" > ../docroot/status.php
echo >> ../docroot/status.php

ZPK_DOCROOT="$(pwd)"
ST_ROOT="$(dirname $ZPK_DOCROOT)"
ZS_PATH=$1
WEB_SRV_DIR=$2

export ZPK_DOCROOT ST_ROOT ZS_PATH WEB_SRV_DIR

chmod +x $ST_ROOT/bin/support_tool.sh
$ST_ROOT/bin/support_tool.sh >> ../docroot/status.php

echo >> ../docroot/status.php
echo "Support Tool execution completed" >> ../docroot/status.php
