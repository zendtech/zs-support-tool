zsstusage()
{
	echo
	echo -n "Usage : $0"
	cat $ZCE_PREFIX/share/support_tool/help.txt
}

export ZSST_ver="PRODUCT_VERSION (Eight) build ST_BUILD"

for option in "$@"; do
	case "$option" in

		"-v")
			echo $ZSST_ver
			exit 0
			;;

		"--help")
			zsstusage
			exit 0
			;;

		"-m"|"--message")
			export STMSG=1
			echo "You will be given an option to add a custom message"
			;;

		"--full")
			export FULLLOGS=1
			echo "Full log collection enabled"
			;;

		"--get-dbs")
			export GETSQLITE=1
			echo "Collecting all internal SQLITE databases enabled"
			;;

		"--clean-monitor")
			export ZSST_ACTION="clean_monitor.sh"
			break
			;;

		"--clean-alerts")
			export ZSST_ACTION="clean_notifications.sh"
			break
			;;

		"--chuser")
			export ZSST_ACTION="ch_apache_user.sh"
			break
			;;

		"--core-dump")
			export ZSST_ACTION="core_dump.sh"
			break
			;;

		"--simple-auth")
			export ZSST_ACTION="simple_auth.sh"
			break
			;;

		"--zray-off")
			export ZSST_ACTION="zray_off.sh"
			break
			;;

		"--update")
			export ZSST_ACTION="update.sh"
			break
			;;

		*)
			echo
			echo "ERROR: Option $option was not recognized. Exiting..."
			zsstusage
			exit 1
			;;
	esac
done
