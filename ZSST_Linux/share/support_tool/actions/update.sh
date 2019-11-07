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
	cd $ZCE_PREFIX/tmp/STlatest || exit 1

	if ! downloadtofile "https://github.com/zendtech/zs-support-tool/releases/latest/download/SupportToolMulti_LinuxSFX.tar.gz" ZSST_latest.tgz; then 
		echo -e "\n\nDownload from GitHub failed. You may find a more detailed error report above.\n"
		rm -rf "$ZCE_PREFIX/tmp/STlatest"
		exit 1
	fi

	tar xf ZSST_latest.tgz
	./SupportToolSFX.bin
	
	rm -rf "$ZCE_PREFIX/tmp/STlatest"
}

cd $ZCE_PREFIX/tmp || exit 1
if ! downloadtofile "https://api.github.com/repos/zendtech/zs-support-tool/releases/latest" online_ver.json; then 
	echo -e "\n\nConnection to GitHub failed. You may find a more detailed error report above.\n"
	exit 1
fi
latestBuild=$($ZCE_PREFIX/bin/php -n -r '$a=file_get_contents("online_ver.json"); $b=json_decode($a,true); echo $b["name"];')
rm -f online_ver.json
currentBuild=$($ZCE_PREFIX/bin/support_tool.sh -v | sed "s@^.*build @@")

echo
if [ "$currentBuild" = "$latestBuild" ]; then
	echo "There is no newer build available. Current build is   $currentBuild."
else
	echo "Installed build:  $currentBuild"
	echo "On-Line build:   $latestBuild"
fi
echo



if [ "$2" = "--check" ]; then
	exit 0
elif [ "$2" = "--auto" ]; then
	installLatest
else
	yesnocommand "Please confirm latest Support Tool build installation" "" installLatest
fi
