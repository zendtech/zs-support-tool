#!/bin/bash
ZSST_PLUGIN_NAME="Configure Zend Server Core Dumps Creation"


if [ $NONSU ]; then
	echo "You need to be superuser to perform this operation."
	exit 1
fi

. $ZCE_PREFIX/share/support_tool/st_funcs.lib

if [ "$2" = "--auto" ]; then
	AUTOMATIC="-y"
elif [ "$2" = "--off" ]; then
	echo "Disabling core dumps generation"
	if [ "$WEB_SRV" = "apache" ]; then
		rm -f /etc/httpd/conf.d/zend_coredump.conf > /dev/null 2>&1
		rm -f /etc/apache2/conf.d/zend_coredump.conf > /dev/null 2>&1
		rm -f /etc/apache2/conf-enabled/zend_coredump.conf > /dev/null 2>&1
		rm -f /lib/systemd/system/httpd.service.d/zend-core-dump.conf > /dev/null 2>&1
		rm -f /lib/systemd/system/apache2.service.d/zend-core-dump.conf > /dev/null 2>&1
	elif [ "$WEB_SRV" = "nginx" ]; then
		rm -f /lib/systemd/system/nginx.service.d/zend-core-dump.conf > /dev/null 2>&1
	fi
	if which systemctl 2> /dev/null; then
		systemctl daemon-reload
	fi
	ocp=$(head -1 $ZCE_PREFIX/var/backups/original_core_pattern)
	if [ "$ocp" != "" ]; then
		echo "$ocp" > /proc/sys/kernel/core_pattern
	fi

	cancelMSG=$(echo -e "\nZend Server needs to be restarted to disable core dumps creation:\n\n	# ulimit -c 0\n	   # $ZCE_PREFIX/bin/zendctl.sh restart\n \n \n ")
	yesnocommand "Confirm restart of Zend Server" "$cancelMSG" "$ZCE_PREFIX/bin/zendctl.sh restart"

	exit 0
elif [ "$2" != "" ]; then
	AUTOMATIC=""
	RELEASE="$2"
elif [ "$3" != "" ]; then
	AUTOMATIC=""
	RELEASE="$3"
else
	AUTOMATIC=""
	RELEASE=""
fi

# otherrepo "/etc/apt/sources.list.d/zend.list" "7.0.0_update3"
function otherrepo
{
	if [ "$2" = "" ]; then
		revert="echo"
		return
	fi

	if [ "$2" = "revertBAK" ]; then
		echo
		mv -f "$1.BAK" "$1"
		return
	fi

	if [ ! -f "$1" ]; then
		echo "The regular repository file $1 could not be found. Exiting..."
		exit 1
	fi

	mv "$1" "$1.BAK"
	sed -r "s@(http://repos\.zend\.com/zend-server)/[0-9a-z_.]+@\1/$2@g" "$1.BAK" > "$1"
	revert="otherrepo $1 revertBAK"
}


mkdir $ZCE_PREFIX/var/core
chmod 777 $ZCE_PREFIX/var/core

PHP_VER=`$ZCE_PREFIX/bin/php -nr "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;"`

downloadtofile "https://raw.githubusercontent.com/php/php-src/PHP-$PHP_VER/.gdbinit" "$ZCE_PREFIX/var/core/.gdbinit"
cat > $ZCE_PREFIX/var/core/.gdbcommands <<EOC
backtrace
backtrace full
source .gdbinit
zbacktrace
EOC

cp $ZCE_PREFIX/share/support_tool/gdb_adv.sh $ZCE_PREFIX/var/core
chmod a+x $ZCE_PREFIX/var/core/gdb_adv.sh


#if [[ "$PHP_VER" > "5.4" ]]; then
#	DBG_LOADER=""
#else
#	DBG_LOADER="php-$PHP_VER-loader-zend-server-dbg"
#fi

DBG_COMMON="zend-server-php-$PHP_VER-dbg gdb"

function set_core_dump_confs {
	if [ "$WEB_SRV" = "apache" ]; then
		if [ "$1" = "apache2" ]; then
			if [ -d "/etc/apache2/conf.d" ]; then
				apacheConf="conf.d"
			elif [ -d "/etc/apache2/conf-enabled" ]; then
				apacheConf="conf-enabled"
			fi
		else
			apacheConf="conf.d"
		fi
		echo "CoreDumpDirectory $ZCE_PREFIX/var/core" > /etc/$1/$apacheConf/zend_coredump.conf
	fi
	if which systemctl 2> /dev/null; then
		mkdir -p /lib/systemd/system/$1.service.d/
		echo -e "[Service]\nLimitCORE=infinity" > /lib/systemd/system/$1.service.d/zend-core-dump.conf
		systemctl daemon-reload
	fi
}

if which apt-get 2> /dev/null; then
	REPOFILE="/etc/apt/sources.list.d/zend.list"
	otherrepo $REPOFILE $RELEASE
	DBG_PHP_BIN="php-$PHP_VER-fpm-zend-server-dbg"
	if [ "$WEB_SRV" = "apache" ]; then
		set_core_dump_confs apache2
		DBG_PHP_BIN="libapache2-mod-php-$PHP_VER-zend-server-dbg php-$PHP_VER-bin-zend-server-dbg"
	elif [ "$WEB_SRV" = "nginx" ]; then
		set_core_dump_confs nginx
	fi
	apt-get update
	apt-get $AUTOMATIC install $DBG_COMMON $DBG_PHP_BIN $DBG_LOADER

elif which yum 2> /dev/null; then
	REPOFILE="/etc/yum.repos.d/zend.repo"
	otherrepo $REPOFILE $RELEASE
	DBG_PHP_BIN="php-$PHP_VER-fpm-zend-server-dbg"
	if [ "$WEB_SRV" = "apache" ]; then
		set_core_dump_confs httpd
		DBG_PHP_BIN="mod-php-$PHP_VER-apache2-zend-server-dbg php-$PHP_VER-bin-zend-server-dbg"
	elif [ "$WEB_SRV" = "nginx" ]; then
		set_core_dump_confs nginx
	fi
	yum clean all
	yum $AUTOMATIC install $DBG_COMMON $DBG_PHP_BIN $DBG_LOADER

else
	echo
	echo "Can't determine which package manager (aptitude, apt-get or yum) should be used for debug symbols installation"
	exit 1
fi


$revert


cat /proc/sys/kernel/core_pattern >> $ZCE_PREFIX/var/backups/original_core_pattern
echo "$ZCE_PREFIX/var/core/core.dump.%p" > /proc/sys/kernel/core_pattern


ulimit -c unlimited

cancelMSG=$(echo -e "\nZend Server needs to be restarted to enable core dumps creation:\n\n	   # ulimit -c unlimited\n	  # $ZCE_PREFIX/bin/zendctl.sh restart\n \n \n ")
yesnocommand "Confirm restart of Zend Server" "$cancelMSG" "$ZCE_PREFIX/bin/zendctl.sh restart"


cat <<EOT


Zend Server and Apache/Nginx are prepared to save core dumps of crashing processes.
Reproduce the crash and check that core dump files have been placed in

$ZCE_PREFIX/var/core


If you want to disable core dump creation, run this command with the '--off' parameter:

$ZCE_PREFIX/bin/support_tool.sh --core-dump --off


If you need to restart Zend Server, but keep it in core dump mode, set the proper limit before Zend Server restart:

ulimit -c unlimited
$ZCE_PREFIX/bin/zendctl.sh restart


EOT
