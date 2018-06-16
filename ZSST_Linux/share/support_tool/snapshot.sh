#!/bin/bash

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



if [ ! -w /etc/passwd ]; then
	echo "You need to run this script as superuser (root)"
fi


if [ "$1" = "prepare" ]; then
	echo -e "\nIstalling debug packages, 'lsof', 'strace' and 'gdb'\n"
	RELEASE="$2"

	WEB_SRV=$(grep "zend.webserver_type" /usr/local/zend/etc/conf.d/ZendGlobalDirectives.ini | cut -d'=' -f2 | tr -d '[:space:]')
	if [ "$WEB_SRV" = "apache" ]; then
		EXCLUDE_PKG="fpm-"
	elif [ "$WEB_SRV" = "nginx" ]; then
		EXCLUDE_PKG="mod-php"
	else
		echo "Can't determine the web server used"
		exit 1
	fi

	PHP_VER=$(/usr/local/zend/bin/php -i | grep "PHP Version => " | head -1 | cut -d">" -f2 | tr -d '[:space:]' | cut -d"." -f1,2)
	COMMON_PKG="gdb lsof strace"

	if which apt-get 2> /dev/null; then
		REPOFILE="/etc/apt/sources.list.d/zend.list"
		otherrepo $REPOFILE $RELEASE
		apt-get update
		DBG_PACKAGE_NAMES=$(apt-cache --names-only search "php-$PHP_VER.*zend.*dbg|zend.*php-$PHP_VER.*dbg" | cut -d" " -f1 | grep -v $EXCLUDE_PKG)
		apt-get install $DBG_PACKAGE_NAMES $COMMON_PKG
	elif which yum 2> /dev/null; then
		REPOFILE="/etc/yum.repos.d/zend.repo"
		otherrepo $REPOFILE $RELEASE
		yum clean all
		DBG_PACKAGE_NAMES=$(yum search zend | grep -E "php-$PHP_VER.*dbg" | cut -d" " -f1 | grep -v $EXCLUDE_PKG)
		yum install $DBG_PACKAGE_NAMES $COMMON_PKG
	else
		echo
		echo "Can't determine which package manager (aptitude, apt-get or yum) should be used for installation"
		exit 1
	fi


	$revert
    exit 0
fi

if [ ! "$1" = "" ]; then
	cat <<HLP

    Usage:
        -  $0
                  collect data about precesses related to Zend Server

        -  $0 prepare [<repository version>]
                  prepare system for data collection by installing
                  debug symbols, 'lsof', 'strace' and 'gdb'. Example:

        $0 prepare 8.5.3


HLP
	exit 1
fi

TS=$(date '+%s')
SD=snapshot_$TS
mkdir $SD > /dev/null 2>&1

plist="$(ps -eo pid,user,command | grep -E "[z]end|[a]pache|[h]ttpd" | sed "s/^\s*//" | cut -d' ' -f1)"
echo -e "\n\nEstimated run time is $(($(wc -l <<<"$plist") * 9 + 5)) sec. Please be patient.\n"

echo "Gathering general information"
/usr/local/zend/bin/zendctl.sh status > $SD/01_status.txt 2>&1
lsof > $SD/02_lsof.txt > /dev/null 2>&1
ps faux > $SD/03_ps.txt
ps -emo uid,user,ppid,pid,tid,pcpu,pmem,vsz,rss,tname,stat,lstart:27,time:15,wchan:35,command >> $SD/03_ps.txt
top -bHcn3 > $SD/04_top.txt

for zpid in $plist; do
	zpidc=$(cat /proc/$zpid/comm)
	zpidf=$(cat /proc/$zpid/cmdline)
	zpide=$(cat /proc/$zpid/environ)
	zpidl=$(cat /proc/$zpid/limits)
	echo "Gathering information about the process '$zpidc' ($zpid)"
	echo -e "$zpid :: $zpidc\n$zpidf\n\n$zpidl\n\n$zpide\n\n" > $SD/proc_${zpidc}_${zpid}.txt
	timeout 5s strace -fp $zpid > $SD/strace_${zpidc}_${zpid}.txt 2>&1
	gcore -o $SD/core_${zpidc} $zpid > /dev/null 2>&1
	gdb --batch -ex 'backtrace full' /proc/$zpid/exe $SD/core_${zpidc}.${zpid} > $SD/core_BT_${zpidc}_${zpid}.txt 2>&1
done

tar czf $SD.tgz $SD
rm $SD/* && rmdir $SD

echo
echo "Thank you. Done in $(($(date '+%s') - $TS)) sec."
echo -e "\n\n-----------------------------------------"
echo -e "The snapshot was created:\n     $(ls -lh "$PWD/$SD.tgz")\n\nPlease contact Zend Support for instructions on uploading the archive.\n"
