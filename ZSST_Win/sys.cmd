@echo off

rem Usage: 'command.cmd "Zend Server Directory" "Support Tool Temp Directory"'

echo Getting the List of Open Connections...
netstat -ona > %2\sys_netstat.txt

echo Getting the List of Running Processes...
tasklist > %2\sys_processes.txt
tasklist /svc >> %2\sys_processes.txt

echo Getting the Network Configuration...
ipconfig /all > %2\sys_ipconfig.txt

echo Getting General System Information...
echo Environment: > %2\sys_info.txt
set >> %2\sys_info.txt
echo ______________________________________________________________ >> %2\sys_info.txt

echo Disks: >> %2\sys_info.txt
rem WMIC doesn't get paths like "disk\path"\file.txt, hence the workaround:
set tmppath=%2
set tmppath="%tmppath:"=%\sys_info.txt"
wmic /append:%tmppath% logicaldisk list brief /format:list
echo ______________________________________________________________ >> %2\sys_info.txt

echo General Info: >> %2\sys_info.txt
systeminfo >> %2\sys_info.txt


echo Exporting Logs...

rem Windows XP, 2003:
rem cscript /nologo %windir%\system32\eventquery.vbs /v /nh /r 200 /fo CSV /l Application > %2\events_application.csv
rem cscript /nologo %windir%\system32\eventquery.vbs /v /nh /r 200 /fo CSV /l System > %2\events_system.csv

rem Windows 7, 2008
wevtutil epl Application %2\events_application.evt
wevtutil epl System %2\events_system.evt
