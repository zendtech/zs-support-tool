#!/bin/bash
ZSST_PLUGIN_NAME="Zend Server Information"
exec >> $ZEND_ERROR_LOG 2>&1


echo "Support Tool version: $ZSST_ver" >> $ZEND_ERROR_LOG


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
scd
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
lsof -x +D $ZCE_PREFIX
du -sh $ZCE_PREFIX/
du -sh $ZCE_PREFIX/*
du -sh $ZCE_PREFIX/var/*
du -sh $ZCE_PREFIX/tmp/*
EOCMD

# /proc data for processes related to Zend
for zpid in $(ps -eo pid,user,command | grep "[z]end" | sed "s/^\s*//" | cut -d' ' -f1); do
	zpidc=$(cat /proc/$zpid/comm)
	zpidf=$(cat /proc/$zpid/cmdline)
	zpide=$(cat /proc/$zpid/environ)
	zpidl=$(cat /proc/$zpid/limits)
	echo -e ">>>>>>>>> $zpid :: $zpidc\n$zpidf\n\n$zpidl\n\n$zpide\n<<<<<<<<< $zpid :: $zpidc\n\n\n" >> $ZEND_DATA_TMPDIR/zs_procinfo.txt
done

# /proc data for Apache
for apid in $(ps -eo pid,user,command | grep "[a]pache" | sed "s/^\s*//" | cut -d' ' -f1); do
	apidc=$(cat /proc/$apid/comm)
	apidf=$(cat /proc/$apid/cmdline)
	apide=$(cat /proc/$apid/environ)
	apidl=$(cat /proc/$apid/limits)
	echo -e ">>>>>>>>> $apid :: $apidc\n$apidf\n\n$apidl\n\n$apide\n<<<<<<<<< $apid :: $apidc\n\n\n" >> $ZEND_DATA_TMPDIR/zs_procinfo.txt
done
for apid in $(ps -eo pid,user,command | grep "/[h]ttpd" | sed "s/^\s*//" | cut -d' ' -f1); do
	apidc=$(cat /proc/$apid/comm)
	apidf=$(cat /proc/$apid/cmdline)
	apide=$(cat /proc/$apid/environ)
	apidl=$(cat /proc/$apid/limits)
	echo -e ">>>>>>>>> $apid :: $apidc\n$apidf\n\n$apidl\n\n$apide\n<<<<<<<<< $apid :: $apidc\n\n\n" >> $ZEND_DATA_TMPDIR/zs_procinfo.txt
done


# MD5 sums start
echo "bin :" > $ZEND_DATA_TMPDIR/zs_md5.txt
md5sum $ZCE_PREFIX/bin/* >> $ZEND_DATA_TMPDIR/zs_md5.txt
echo "lib :" >> $ZEND_DATA_TMPDIR/zs_md5.txt
find $ZCE_PREFIX/lib -type f -exec md5sum {} \; >> $ZEND_DATA_TMPDIR/zs_md5.txt
# MD5 sums end


ls -RAlF $ZCE_PREFIX/ > $ZEND_DATA_TMPDIR/zs_dir.txt

cp /etc/zce.rc $ZEND_DATA_TMPDIR/zs_rc.txt
cp -R $ZCE_PREFIX/etc $ZEND_DATA_TMPDIR/zend_etc
cp -R $ZCE_PREFIX/gui/lighttpd/etc $ZEND_DATA_TMPDIR/lighttpd_etc
cp -R $ZCE_PREFIX/gui/config $ZEND_DATA_TMPDIR/gui_config

mkdir $ZEND_DATA_TMPDIR/php_config
tar cf - $ZCE_PREFIX/php/7.*/etc | tar --strip-components=4 -C $ZEND_DATA_TMPDIR/php_config -xf -

if [ "$WEB_SRV" = "apache" ]; then
	# Apache configuration
	if [ -d /etc/httpd ]; then
		# Workaroung for RHEL placing logs inside etc
		# rsync -rL --exclude=logs /etc/httpd/ $ZEND_DATA_TMPDIR/apache_config
		mkdir $ZEND_DATA_TMPDIR/apache_config
		tar --exclude='logs' --exclude='modules' cf - /etc/httpd | tar -C $ZEND_DATA_TMPDIR/apache_config -xf -
	elif [ -d /etc/apache ]; then
		cp -RL /etc/apache $ZEND_DATA_TMPDIR/apache_config
	elif [ -d /etc/apache2 ]; then
		cp -RL /etc/apache2 $ZEND_DATA_TMPDIR/apache_config
	else
		echo "Apache configuration not found" >> ${ZEND_ERROR_LOG}
	fi

	apachectl -S 1>> $ZEND_DATA_TMPDIR/zs_apachectl.txt 2>> ${ZEND_ERROR_LOG}
	apache2ctl -S 1>> $ZEND_DATA_TMPDIR/zs_apachectl.txt 2>> ${ZEND_ERROR_LOG}
elif [ "$WEB_SRV" = "nginx" ]; then
	# nginx configuration
	if [ -d /etc/nginx ]; then
		cp -RL /etc/nginx $ZEND_DATA_TMPDIR/nginx_config
	else
		echo "nginx configuration not found" >> ${ZEND_ERROR_LOG}
	fi

	nginx -vt > $ZEND_DATA_TMPDIR/zs_nginx_conf.txt 2>&1
fi
