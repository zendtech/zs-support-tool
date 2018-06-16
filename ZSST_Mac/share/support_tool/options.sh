zsstusage()
{
	echo
	echo -n "Usage : $0"
	cat $ZCE_PREFIX/share/support_tool/help.txt
}


for option in "$@"; do
	case "$option" in

		"-v")
			echo "PRODUCT_VERSION (Hot Dog)"
			exit 0
			;;

		"--help")
			zsstusage
			exit 0
			;;

		"-m"|"--message")
			export $STMSG=1
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

		*)
			echo
			echo "ERROR: Option $option was not recognized. Exiting..."
			zsstusage
			exit 1
			;;
	esac
done
