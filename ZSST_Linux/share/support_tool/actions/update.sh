#!/bin/bash
ZSST_PLUGIN_NAME="Support Tool Update"


if [ $NONSU ]; then
	echo "You need to be superuser to perform this operation."
	exit 1
fi

. $ZCE_PREFIX/share/support_tool/st_funcs.lib

function installLatest
{
	mkdir $ZCE_PREFIX/tmp/STlatest
	cd $ZCE_PREFIX/tmp/STlatest

	ZEND_ERROR_LOG=/dev/null
	downloadtofile "http://us-up.zend.com/files/lateST.php?redirect" ZSST_latest.tgz

	tar xf ZSST_latest.tgz
	./SupportToolSFX.bin
	
	cd $ZCE_PREFIX/tmp
	rm -rf STlatest
}


latestBuild=$(curl -s http://us-up.zend.com/files/lateST.php | sed -e "s@SupportToolSFX_@@" -e "s@\.tar\.gz@@" | cut -d'_' -f2)
currentBuild=$($ZCE_PREFIX/bin/support_tool.sh -v | sed "s@^.*build @@")

echo
if [ "$currentBuild" = "$latestBuild" ]; then
	echo "There is no newer build available. Current build is   $currentBuild."
else
	echo "Current build:  $currentBuild"
	echo "Latest build:   $latestBuild"
fi
echo



if [ "$2" = "--check" ]; then
	exit 0
elif [ "$2" = "--auto" ]; then
	installLatest
else
	yesnocommand "Please confirm latest Support Tool build installation" "" installLatest
fi
