#!/bin/bash

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

# downloadtofile "URL" "outpit file"
function downloadtofile
{

if command -v wget > /dev/null 2>&1 ;then
	wget -O $2 $1 2>/dev/null

elif command -v aria2c > /dev/null 2>&1 ;then
	aria2c -j 1 -s 1 -o $2 $1 > /dev/null

elif command -v curl > /dev/null 2>&1 ;then
	curl -sLo $2 $1

else
	echo "wget, aria2c or curl not found."

fi
}


if [ ! -w /etc/passwd ]; then
	echo "You need to run this script as superuser (root)"
fi


if [ "$1" = "prepare" ]; then
	echo -e "\nIstalling debug packages, 'lsof', 'strace' and 'gdb'\n"
	RELEASE="$2"

	PHP_VER=`/usr/local/zend/bin/php -nr "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;"`
	WEB_SRV=$(grep "zend.webserver_type" /usr/local/zend/etc/conf.d/ZendGlobalDirectives.ini | cut -d'=' -f2 | tr -d '[:space:]')

	# not including 'php-$PHP_VER-fcgi-zend-server-dbg' because it seems to cause bogus conflict in YUM
	DBG_COMMON="gdb lsof strace zend-server-php-$PHP_VER-dbg php-$PHP_VER-bin-zend-server-dbg"

	APTcmd=apt-get
	if command -v $APTcmd 2> /dev/null; then
		REPOFILE="/etc/apt/sources.list.d/zend.list"
		otherrepo $REPOFILE $RELEASE
		DBG_PHP_BIN="php-$PHP_VER-fpm-zend-server-dbg"
		if [ "$WEB_SRV" = "apache" ]; then
			SAPI=$(grep -E '^\s*zend.php_sapi\s*=' $ZCE_PREFIX/etc/conf.d/ZendGlobalDirectives.ini | sed 's@ @@g' | cut -d '=' -f 2)
			if [ "$SAPI" != "fpm" ]; then
				DBG_PHP_BIN="libapache2-mod-php-$PHP_VER-zend-server-dbg"
			fi
		fi
		$APTcmd update
		$APTcmd $AUTOMATIC install $DBG_COMMON $DBG_PHP_BIN

	elif command -v yum 2> /dev/null; then
		REPOFILE="/etc/yum.repos.d/zend.repo"
		otherrepo $REPOFILE $RELEASE
		DBG_PHP_BIN="php-$PHP_VER-fpm-zend-server-dbg"
		if [ "$WEB_SRV" = "apache" ]; then
			SAPI=$(grep -E '^\s*zend.php_sapi' $ZCE_PREFIX/etc/conf.d/ZendGlobalDirectives.ini | sed 's@ @@g' | cut -d '=' -f 2)
			if [ "$SAPI" != "fpm" ]; then
				DBG_PHP_BIN="mod-php-$PHP_VER-apache2-zend-server-dbg"
			fi
		fi
		yum clean all
		yum $AUTOMATIC install $DBG_COMMON $DBG_PHP_BIN
	else
		echo
		echo "Can't determine which package manager ($APTcmd or yum) should be used for debug symbols installation"
		exit 1
	fi

    downloadtofile "https://raw.githubusercontent.com/php/php-src/PHP-$PHP_VER/.gdbinit" "/usr/local/zend/tmp/.gdbinit_php"
    cat > /usr/local/zend/tmp/.gdbcommands <<EOC
backtrace
backtrace full
source .gdbinit_php
zbacktrace
EOC


	$revert
    exit 0
fi

if echo "$1" | grep -E '(--)grep=.+' > /dev/null 2>&1; then
	filter=$(echo "$1" | sed 's@--grep=@@')
	GList="$(ps -eTo spid,user,command | grep -E "$filter" | grep -v "$0"| sed "s/^\s*//g" | cut -d' ' -f1)"
	plist="$GList"
	if echo "$2" | grep -E '(--)lsof=.+' > /dev/null 2>&1; then
		args=$(echo "$2" | sed 's@--lsof=@@')
		LList_filter="\s$(echo $(lsof -F p $args | grep -E '^p' | sed -e 's@p@@g') -e 's@\s@\\s|\\s@g')\s"
		plist="$(echo "$GList" | sed -e "s/^/ /g" -e "s/$/ /g" | grep -E "$LList_filter")"
	fi
elif echo "$1" | grep -E '(--)lsof=.+' > /dev/null 2>&1; then
	args=$(echo "$1" | sed 's@--lsof=@@')
	LList="$(lsof -F p $args | grep -E '^p' | sed 's@p@@g')"
	plist="$LList"
	if echo "$2" | grep -E '(--)grep=.+' > /dev/null 2>&1; then
		filter=$(echo "$2" | sed 's@--grep=@@')
		LList_filter="\s$(echo $LList | sed 's@\s@\\s|\\s@g')\s"
		plist="$(ps -eTo spid,user,command | sed "s/^/ /g" | grep -E "$LList_filter" | grep -E "$filter" | grep -v "$0" | sed "s/^\s*//g" | cut -d' ' -f1)"
	fi
else
    if [ ! "$1" = "" ]; then
		echo $1
		echo $2
        cat <<HLP

        Usage:
            -  $0
                    collect data about precesses related to Zend Server

            -  $0 prepare [<repository version>]
                    prepare system for data collection by installing
                    debug symbols, 'lsof', 'strace' and 'gdb'
            e.g.: $0 prepare 8.5.3


            -  $0 --grep="<filter regex>"
                    filter the processes (SPID, user and command) by grep
            e.g.: $0 --grep="httpd"


			-  $0 --lsof="<arguments>"
					filter processes by lsof
			e.g.: $0 --lsof="-x +D /var/www/html/reports"

			"--grep" and "--lsof" can be combined and will be applied in
			the order they are specified
			e.g.: $0 filter 

HLP
        exit 1
    fi
    plist="$(ps -eo pid,user,command | grep -E "[z]end|[a]pache|[h]ttpd" | grep -v "$0" | sed "s/^\s*//" | cut -d' ' -f1)"
fi

if [ "$plist" = "" ]; then
	echo
	echo "Nothing to process. Try a different set of filters."
	echo
	exit 0
fi

echo
echo "SPID processing list:"
echo $plist

TS=$(date '+%s')
SD=snapshot_$TS
mkdir $SD > /dev/null 2>&1

echo -e "\n\nConservative run time approximation is $(($(wc -l <<<"$plist") * 3 + 15)) sec.\n  Please be patient.\n"

echo "Gathering general information"
/usr/local/zend/bin/zendctl.sh status > $SD/01_status.txt 2>&1
lsof > $SD/02_lsof.txt 2>&1 &
ps faux > $SD/03_ps.txt &
ps -emo uid,user,ppid,pid,tid,pcpu,pmem,vsz,rss,tname,stat,lstart:27,time:15,wchan:35,command >> $SD/03_ps.txt &
top -bHcn3 > $SD/04_top.txt &

for zpid in $plist; do
	zpidc=$(cat /proc/$zpid/comm)
	zpidf=$(cat /proc/$zpid/cmdline)
	zpide=$(cat /proc/$zpid/environ)
	zpidl=$(cat /proc/$zpid/limits)
	echo "Gathering information about the process '$zpidc' ($zpid)"
	echo -e "$zpid :: $zpidc\n$zpidf\n\n$zpidl\n\n$zpide\n\n" > $SD/proc_${zpidc}_${zpid}.txt
	timeout 5s strace -fp $zpid > $SD/strace_${zpidc}_${zpid}.txt 2>&1 &
done

bg=20
until [ $bg -lt 1 ]; do
    sleep 2
    bg=$(($(jobs | grep Running | grep strace_ | wc -l) + 0 ))
    if [ $bg -gt 0 ]; then
        echo "$bg still in strace"
    fi
done

: <<'DISABLED_DUMP_N_PARSE'
echo "Starting core dump"
for zpid in $plist; do
	zpidc=$(cat /proc/$zpid/comm)
	gcore -o $SD/core_${zpidc} $zpid > /dev/null 2>&1 &
done

bg=20
until [ $bg -lt 1 ]; do
    sleep 5
    bg=$(($(jobs | grep Running | grep core_ | wc -l) + 0 ))
    if [ $bg -gt 0 ]; then
        echo "$bg still in core dump"
    fi
done

echo "Starting core parse"
cd $SD
cp /usr/local/zend/tmp/.gdb* .
for zpid in $plist; do
	zpidc=$(cat /proc/$zpid/comm)
	gdb -batch -x .gdbcommands /proc/$zpid/exe core_${zpidc}.${zpid} > core_traces_${zpidc}_${zpid}.txt 2>&1 &
done

echo "Starting core parse"
cd $SD
cp /usr/local/zend/tmp/.gdb* .
for zpid in $plist; do
	zpidc=$(cat /proc/$zpid/comm)
	gdb -batch -x .gdbcommands /proc/$zpid/exe core_${zpidc}.${zpid} > core_traces_${zpidc}_${zpid}.txt 2>&1 &
done

bg=20
until [ $bg -lt 1 ]; do
    sleep 5
    bg=$(($(jobs | grep Running | grep core_traces_ | wc -l) + 0 ))
    if [ $bg -gt 0 ]; then
        echo "$bg still in core parse"
    fi
done
DISABLED_DUMP_N_PARSE


echo "Starting backtracing"
cd $SD
cp /usr/local/zend/tmp/.gdb* .
for zpid in $plist; do
	zpidc=$(cat /proc/$zpid/comm)
	if echo $zpidc | grep -E "php|apache|^httpd" > /dev/null; then
		gdb -n -p $zpid --batch \
		-ex "set logging redirect on" \
		-ex "set logging file backtrace_${zpidc}_${zpid}.txt" \
		-ex "set logging on" \
		-ex "backtrace full" \
		-ex "set logging off" \
		-ex "set logging file php_stack_${zpidc}_${zpid}.txt" \
		-ex "set logging on" \
		-ex "source .gdbinit_php" \
		-ex "zbacktrace" > /dev/null 2>&1 &
	else
		gdb -n -p $zpid --batch \
		-ex "set logging redirect on" \
		-ex "set logging file backtrace_${zpidc}_${zpid}.txt" \
		-ex "set logging on" \
		-ex "backtrace full" > /dev/null 2>&1 &
	fi
done

bg=20
until [ $bg -lt 1 ]; do
    sleep 2
    bg=$(($(jobs | grep Running | grep backtrace_ | wc -l) + 0 ))
    if [ $bg -gt 0 ]; then
        echo "$bg still in backtrace"
    fi
done

echo
echo "Done! Now packing..."

cd ..
sleep 5
tar czf $SD.tgz $SD
rm $SD/* $SD/.gdb* && rmdir $SD

echo
echo "Thank you. Done in $(($(date '+%s') - $TS)) sec."
echo -e "\n\n-----------------------------------------"
echo -e "The snapshot was created:\n     $(ls -lh "$PWD/$SD.tgz")\n\nPlease contact Zend Support for instructions on uploading the archive.\n"
