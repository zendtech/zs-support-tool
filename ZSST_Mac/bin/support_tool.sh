#!/bin/bash

SYSTMPDIR=$TMPDIR

if [ -f /etc/zce.rc ];then
	source /etc/zce.rc
else
	echo "/etc/zce.rc doesn't exist!"
	exit 1;
fi

PATH=$PATH:$ZCE_PREFIX/bin

if [ ! -d "$SYSTMPDIR" ]; then 
	SYSTMPDIR="/tmp"
fi

STAMP=`date +%F-%H%M%S`
ZEND_DATA_DIR=ZSST_${STAMP}
ZEND_DATA_TMPDIR=${SYSTMPDIR}/${ZEND_DATA_DIR}
ZEND_ERROR_LOG=${ZEND_DATA_TMPDIR}/support_tool_error.log
ZEND_COMPRESSED_REPORT=ZSST_${STAMP}.tar.gz

export ZCE_PREFIX
export ZEND_DATA_DIR
export ZEND_DATA_TMPDIR
export ZEND_ERROR_LOG
export WEB_USER


if [ ! -w /etc/passwd ]; then
	echo "WARNING: Some functionality may be disabled."
	echo "Switch to superuser for full functionality."
	export NONSU=1
	echo  "--- Non-superuser execution" >> $ZEND_ERROR_LOG
#	exit 1
fi


# ZSST parse command line
source $ZCE_PREFIX/share/support_tool/options.sh



mkdir -p $ZEND_DATA_TMPDIR
cd $ZEND_DATA_TMPDIR

# ZSST plugins start
echo "Plugins :"

ZSST_PLUGINS=$(find $ZCE_PREFIX/share/support_tool/plugins -type f -name "*.sh" -print)

while read PLUGIN; do
	export "$( grep -m1 'ZSST_PLUGIN_NAME=' $PLUGIN)"
	$PLUGIN
	echo " $ZSST_PLUGIN_NAME"

done <<EOI
$ZSST_PLUGINS
EOI
# ZSST plugins end

if [ $STMSG ]; then
	cat <<EOF

The information was collected successfully.
Use free text to describe the issue in your own words.
To submit the information press CONTROL-D

EOF
	cat > $ZEND_DATA_TMPDIR/free_problem_desc
fi
cd $SYSTMPDIR
tar czf ${ZEND_COMPRESSED_REPORT} ${ZEND_DATA_DIR}
if [ $? -eq 0 ];then
    rm -rf $ZEND_DATA_TMPDIR
    echo "Archive created at $SYSTMPDIR/${ZEND_COMPRESSED_REPORT}"
else
    echo "Could not create the archive, leaving $ZEND_DATA_TMPDIR behind for you to archive manually."
fi

