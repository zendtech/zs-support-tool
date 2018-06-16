#!/bin/bash
ZSST_PLUGIN_NAME="System Information"
exec >> $ZEND_ERROR_LOG 2>&1


while read command; do
	COLUMNS=800 $command >> $ZEND_DATA_TMPDIR/system_$(echo "$command" | cut -d " " -f 1).txt
done <<EOCMD
ifconfig
ip address
ipcs -a
netstat -anp
ss -nltup
ss -naop
ldconfig --version
ldconfig -p
ps faux
ps -emo uid,user,ppid,pid,tid,pcpu,pmem,vsz,rss,tname,stat,lstart:27,time:15,wchan:35,command
top -bcHn1
free -m
df -h
iptables -L
locale
ulimit -a
vmstat -a
vmstat -d
vmstat -s
EOCMD

# System's Java path for JavaBridge issues
if which java > /dev/null 2>&1 ; then
	readlink -f $(which java) > $ZEND_DATA_TMPDIR/system_java.txt
fi

# Zend Server semaphore IDs
grep . $ZCE_PREFIX/tmp/*_semid >> system_ipcs.txt


if which php > /dev/null 2>&1 ;then
	ls -l $(which php) > $ZEND_DATA_TMPDIR/system_php.txt
	php -i >> $ZEND_DATA_TMPDIR/system_php.txt
fi


if which getenforce > /dev/null 2>&1 ;then
	getenforce > $ZEND_DATA_TMPDIR/system_getenforce.txt
fi


if which apt-get > /dev/null 2>&1 ; then
	dpkg -l > $ZEND_DATA_TMPDIR/system_deb.txt
	tar czf $ZEND_DATA_TMPDIR/system_apt.tgz /etc/apt
	cp /etc/debian_version $ZEND_DATA_TMPDIR/system_debian_ver.txt
elif which yum > /dev/null 2>&1 ; then
	rpm -qa > $ZEND_DATA_TMPDIR/system_rpm.txt
	tar czf $ZEND_DATA_TMPDIR/system_yum.tgz /etc/yum*
fi
