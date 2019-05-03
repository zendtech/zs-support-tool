@echo off

rem Usage: 'command.cmd "Zend Server Directory" "Support Tool Temp Directory"'

echo "Getting Directory Listing..."
dir /s /oGN %1 > %2\zs_dir.txt
rem cacls %1 /t >> %2\dir.txt

