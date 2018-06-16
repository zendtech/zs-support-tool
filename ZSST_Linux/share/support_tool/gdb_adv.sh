#!/bin/bash

if [ "$1" = "--help" ]; then
	cat <<EOH

This script will try to extract some backtrace information from core dumps
   and then pack all of it into a tarball. The script's working directory
   is /usr/local/zend/var/core

USAGE

Running without parameters will scan for core.dump.<PID> files in the
   working directory and then process every file found.

The script can also be run with paths of core files that need to be processed.
   In this case the core dump file may not be in /usr/local/zend/var/core,
   but the directory containing the core dump should be writable:
   
   $0 php_7253 core.51* core.dump.???? /home/user/core_dump_1885



EOH
exit 0
fi

if [ ! -w /etc/passwd ]; then
	echo "You need to be superuser to run this script"
	exit 1
fi

cd /usr/local/zend/var/core

#wget "https://raw.githubusercontent.com/php/php-src/master/.gdbinit" 2>/dev/null

#cat > .gdbcommands <<EOC
#backtrace
#backtrace full
#source .gdbinit
#zbacktrace
#EOC

if [ $# -gt 0 ]; then
	for dump in $@; do
		if [ -f $dump ]; then
			echo "Processing  $dump ..."
			binary=$(readelf -n $dump | grep -E "^\s+/" | head -1 | tr -d '[:space:]')
			gdb -batch -x .gdbcommands $binary $dump > $dump.traces.txt 2>&1
			echo $dump >> .tarlist
			echo $dump.traces.txt >> .tarlist
		fi
	done
else
	for dump in core.dump.*[!a-z.]; do
		echo "Processing  $dump ..."
		binary=$(readelf -n $dump | grep -E "^\s+/" | head -1 | tr -d '[:space:]')
		gdb -batch -x .gdbcommands $binary $dump > $dump.traces.txt 2>&1
		echo $dump >> .tarlist
		echo $dump.traces.txt >> .tarlist
	done
fi

archive="core.dumps.$(date +%F-%H%M%S).tgz"

tar -czf "$archive" -T .tarlist && echo "Core dumps archive successfully created - /usr/local/zend/var/core/$archive"
rm -f .tarlist
