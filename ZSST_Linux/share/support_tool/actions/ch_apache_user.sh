#!/bin/bash
ZSST_PLUGIN_NAME="Change Web Server User and Group in Zend Server"


if [ $NONSU ]; then
	echo "You need to be superuser to perform this operation."
	exit 1
fi

if [ $# -lt 3 ]; then
cat <<EOT

Usage: ./support_tool.sh --chuser olduser:oldgroup newuser:newgroup

EOT
	exit 1
fi


. $ZCE_PREFIX/share/support_tool/st_funcs.lib


OLD_USER=$(echo $2 | cut -sd":" -f1)
OLD_GROUP=$(echo $2 | cut -sd":" -f2)
NEW_USER=$(echo $3 | cut -sd":" -f1)
NEW_GROUP=$(echo $3 | cut -sd":" -f2)

if [ $OLD_USER ] && [ $OLD_GROUP ] && [ $NEW_USER ] && [ $NEW_GROUP ]; then
	echo
else
cat <<EOT

You did not specify one of the following:
Old Apache User: $OLD_USER
Old Apache Group: $OLD_GROUP
New Apache User: $NEW_USER
New Apache Group: $NEW_GROUP

Usage: ./support_tool.sh --chuser olduser:oldgroup newuser:newgroup

EOT
	exit 1
fi


OLD_UID=$(id -u $OLD_USER)
NEW_UID=$(id -u $NEW_USER)
OLD_GID=$(grep -E "^\s*$OLD_GROUP:" /etc/group | cut -d":" -f3)
NEW_GID=$(grep -E "^\s*$NEW_GROUP:" /etc/group | cut -d":" -f3)


if [ $OLD_UID ] && [ $OLD_GID ] && [ $NEW_UID ] && [ $NEW_GID ]; then
	echo
else
cat <<EOT

Failed to determine one of the following:
Old Apache UID: $OLD_UID
Old Apache GID: $OLD_GID
New Apache UID: $NEW_UID
New Apache GID: $NEW_GID

EOT
	exit 1
fi



yesnocommand "Confirm stopping Zend Server" "Zend Server needs to be stopped to continue this operation." "$ZCE_PREFIX/bin/zendctl.sh stop"

sed -i "s@WEB_USER=$OLD_USER@WEB_USER=$NEW_USER@" /etc/zce.rc


sed -i "s@zend\.httpd_uid=.*@zend\.httpd_uid=$NEW_UID@" $ZCE_PREFIX/etc/conf.d/ZendGlobalDirectives.ini
sed -i "s@zend\.httpd_gid=.*@zend\.httpd_gid=$NEW_GID@" $ZCE_PREFIX/etc/conf.d/ZendGlobalDirectives.ini


find $ZCE_PREFIX -user $OLD_UID -exec chown $NEW_UID {} \;
find $ZCE_PREFIX -group $OLD_GID -exec chgrp $NEW_GID {} \;


usermod -aG $NEW_GID zend

if [ "$WEB_SRV" = "nginx" ]; then
	cd $ZCE_PREFIX/etc/php-fpm.d
	tar czf php-fpm.d.conf.ZSST_BAK-$(date +%Y%m%d%H%M).tgz *.conf

	sed -i "s@^\s*user\s*=\s*$OLD_USER\s*@user = $NEW_USER@g" *.conf
	sed -i "s@^\s*group\s*=\s*$OLD_GROUP\s*@group = $NEW_GROUP@g" *.conf
	sed -i "s@^\s*listen\.owner\s*=\s*$OLD_USER\s*@listen.owner = $NEW_USER@g" *.conf
	sed -i "s@^\s*listen\.group\s*=\s*$OLD_GROUP\s*@listen.group = $NEW_GROUP@g" *.conf
fi

yesnocommand "Confirm starting Zend Server" "Zend Server was not started. You need to start it manually." "$ZCE_PREFIX/bin/zendctl.sh start"
