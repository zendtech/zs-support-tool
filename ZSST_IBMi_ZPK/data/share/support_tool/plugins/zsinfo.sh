#!/usr/bin/ksh
true
#shellcheck disable=SC2034
ZSST_PLUGIN_NAME="Zend Server Information Collector"
exec >> $ZEND_ERROR_LOG 2>&1

# Manifest start
mkdir $ZEND_DATA_TMPDIR/zs_manifest

$ZCE_PREFIX/bin/ZManifest -vi $ZCE_PREFIX/lib/ZendExtensionManager.so >  $ZEND_DATA_TMPDIR/zs_manifest/ZendExtensionManager.so.txt

for ext in $ZCE_PREFIX/lib/*/php-*.*.x/*.so
do
	$ZCE_PREFIX/bin/ZManifest -vi  $ext > "$ZEND_DATA_TMPDIR/zs_manifest/$(basename $ext).txt"
done

while read daemon; do
	$ZCE_PREFIX/bin/ZManifest -vi  $ZCE_PREFIX/bin/$daemon > $ZEND_DATA_TMPDIR/zs_manifest/bin_$daemon.txt
done <<EODEAMONS
jqd
MonitorNode
php.bin
php-cgi.bin
zdd
zdpack
zmd
zsd
EODEAMONS
# Manifest end

while read command; do
	#shellcheck disable=SC2046
	# SC2046 - avoiding complicated quoting, also, cut makes sure we don't get spaces in names
	$command >> $ZEND_DATA_TMPDIR/zs_$(echo "$command" | cut -d " " -f 1).txt
done <<EOCMD
du -sm $ZCE_PREFIX/
du -sm $ZCE_PREFIX/*
du -sm $ZCE_PREFIX/var/*
du -sm $ZCE_PREFIX/tmp/*
EOCMD

ls -alrtR $ZCE_PREFIX/ > $ZEND_DATA_TMPDIR/zs_dir.txt

cp $ZCE_PREFIX/etc/zce.rc $ZEND_DATA_TMPDIR/zs_rc.txt
cp -R $ZCE_PREFIX/etc $ZEND_DATA_TMPDIR/zend_etc
cp -R $ZCE_PREFIX/gui/config $ZEND_DATA_TMPDIR/gui_config

mkdir -p $ZEND_DATA_TMPDIR/php_config/7.1
mkdir $ZEND_DATA_TMPDIR/php_config/7.2
mkdir $ZEND_DATA_TMPDIR/php_config/7.3
cp -R $ZCE_PREFIX/php/7.2/etc $ZEND_DATA_TMPDIR/php_config/7.1
cp -R $ZCE_PREFIX/php/7.2/etc $ZEND_DATA_TMPDIR/php_config/7.2
cp -R $ZCE_PREFIX/php/7.3/etc $ZEND_DATA_TMPDIR/php_config/7.3
