#!/bin/bash
ZSST_PLUGIN_NAME="Zend Server Information"
exec >> $ZEND_ERROR_LOG 2>&1


# root-specific commands
if [ ! $NONSU ]; then
	$ZCE_PREFIX/bin/zendctl.sh status > $ZEND_DATA_TMPDIR/zs_status.txt 2>&1
fi




# Users start
zenduser=$(id -a zend)
apacheuser=$(id -a ${WEB_USER})
gduser=$(grep "zend.httpd_" $ZCE_PREFIX/etc/ZendGlobalDirectives.ini)

cat > $ZEND_DATA_TMPDIR/zs_users.txt <<EOUSERS

Zend User:
$zenduser


Apache User:
$apacheuser


In Global Directives:
$gduser


EOUSERS
# Users end


# Manifest start
mkdir $ZEND_DATA_TMPDIR/zs_manifest

$ZCE_PREFIX/bin/ZManifest -vi $ZCE_PREFIX/lib/ZendExtensionManager.so >  $ZEND_DATA_TMPDIR/zs_manifest/ZendExtensionManager.so.txt

for ext in $ZCE_PREFIX/lib/*/php-*.*.x/*.so; do
	$ZCE_PREFIX/bin/ZManifest -vi  $ext > $ZEND_DATA_TMPDIR/zs_manifest/$(basename $ext).txt
done

while read daemon; do
	$ZCE_PREFIX/bin/ZManifest -vi  $ZCE_PREFIX/bin/$daemon > $ZEND_DATA_TMPDIR/zs_manifest/bin_$daemon.txt
done <<EODEAMONS
jqd
MonitorNode
php
php-cgi
watchdog
zdd
zdpack
zmd
zsd
EODEAMONS
# Manifest end

while read command; do
	$command >> $ZEND_DATA_TMPDIR/zs_$(echo "$command" | cut -d " " -f 1).txt
done <<EOCMD
lsof +D $ZCE_PREFIX
du -sh $ZCE_PREFIX/
du -sh $ZCE_PREFIX/*
du -sh $ZCE_PREFIX/var/*
du -sh $ZCE_PREFIX/tmp/*
EOCMD


# SHA-1 sums start
echo "bin :" > $ZEND_DATA_TMPDIR/zs_sha.txt
shasum $ZCE_PREFIX/bin/* >> $ZEND_DATA_TMPDIR/zs_sha.txt
echo "lib :" >> $ZEND_DATA_TMPDIR/zs_sha.txt
find $ZCE_PREFIX/lib -type f -exec shasum {} \; >> $ZEND_DATA_TMPDIR/zs_sha.txt
# SHA-1 sums end


ls -RAlF $ZCE_PREFIX > $ZEND_DATA_TMPDIR/zs_dir.txt

cp /etc/zce.rc $ZEND_DATA_TMPDIR/zs_rc.txt
cp -R $ZCE_PREFIX/etc $ZEND_DATA_TMPDIR/zend_etc
cp -R $ZCE_PREFIX/gui/lighttpd/etc $ZEND_DATA_TMPDIR/lighttpd_etc
cp -R $ZCE_PREFIX/gui/config $ZEND_DATA_TMPDIR/gui_config

# Databases are not accessible for a regular user
if [ ! $NONSU ]; then

	mkdir $ZEND_DATA_TMPDIR/zs_sqlite
	for dbfile in $ZCE_PREFIX/var/db/*.db; do
		echo -n "$dbfile : " >> $ZEND_DATA_TMPDIR/zs_sqlite/integrity.txt
		sqlite3 $dbfile "PRAGMA integrity_check;" >> $ZEND_DATA_TMPDIR/zs_sqlite/integrity.txt
	done
	echo >> $ZEND_DATA_TMPDIR/zs_sqlite/integrity.txt
	ls -hAlF $ZCE_PREFIX/var/db/ >> $ZEND_DATA_TMPDIR/zs_sqlite/integrity.txt
	
	# codetracing.db doesn't have a version record
	while read db table; do
		echo "$db :" >> $ZEND_DATA_TMPDIR/zs_sqlite/schema_ver.txt
		sqlite3 -line $ZCE_PREFIX/var/db/$db "SELECT * from ${table};" >> $ZEND_DATA_TMPDIR/zs_sqlite/schema_ver.txt
		echo >> $ZEND_DATA_TMPDIR/zs_sqlite/schema_ver.txt
	done <<EODBS
deployment.db deployment_properties
gui.db gui_metadata
jobqueue.db version
monitor.db version
statistics.db schema_properties
devbar.db devbar_properties
zsd.db zsd_schema_properties
urlinsight.db urlinsight_properties
EODBS

	if [ $GETSQLITE ]; then
		cp $ZCE_PREFIX/var/db/* $ZEND_DATA_TMPDIR/zs_sqlite/
	fi

fi

# Apache configuration
cp -R $ZCE_PREFIX/apache2/conf $ZEND_DATA_TMPDIR/apache_config
cp -R $ZCE_PREFIX/apache2/conf.d $ZEND_DATA_TMPDIR/apache_config/conf.d
