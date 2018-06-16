
[Setup]
SetupIconFile=zsst.ico
AppName=Zend Server 2018.0 Support Tool
VersionInfoVersion=2018.0.0.0
VersionInfoDescription=Zend Server 2018.0 Support Tool (Laura)
AppVersion=2018.0
AppPublisher=Rogue Wave Software, Ltd.
AppPublisherURL=http://support.roguewave.com
DefaultDirName={tmp}\ZS9ST
DisableProgramGroupPage=yes
Uninstallable=no
DisableDirPage=yes
DisableWelcomePage=yes
DisableReadyPage=yes
DisableFinishedPage=yes
ShowLanguageDialog=no
WizardSmallImageFile=ZSxST.bmp


[Languages]
Name: "en"; MessagesFile: "ZSxST.isl"


[Files]
Source: "7z.exe"; Flags: dontcopy
Source: "7z.dll"; Flags: dontcopy
Source: "zs.cmd"; Flags: dontcopy
Source: "sys.cmd"; Flags: dontcopy
Source: "curl.exe"; Flags: dontcopy
Source: "libssh2.dll"; Flags: dontcopy
Source: "libeay32.dll"; Flags: dontcopy
Source: "ssleay32.dll"; Flags: dontcopy
Source: "list_logs.php"; Flags: dontcopy
Source: "mysql.php"; Flags: dontcopy
Source: "checLic.php"; Flags: dontcopy


[Types]
Name: "min"; Description: "Basic"
Name: "max"; Description: "Full"
Name: "custom"; Description: "Custom"; Flags: iscustom

[Components]
Name: options; Description: "Create Support Tool archive with these Options:"; Types: min max custom; Flags: exclusive
Name: options\full; Description: "Full logs (by default only last 1000 lines)"; Types: max custom; Flags: dontinheritcheck
Name: options\sqlite; Description: "SQLite databases"; Types: max custom; Flags: dontinheritcheck

Name: actions; Description: "Perform this Action:"; Types: custom; Flags: exclusive
Name: actions\passwd; Description: "Change the 'admin' password"; Types: custom; Flags: exclusive
Name: actions\simple; Description: "Switch to Simple Authentication"; Types: custom; Flags: exclusive
Name: actions\services; Description: "Zend Server services:"; Types: custom; Flags: exclusive
Name: actions\services\stop; Description: "Stop"; Types: custom; Flags: exclusive
Name: actions\services\start; Description: "Start"; Types: custom; Flags: exclusive
Name: actions\services\restart; Description: "Restart"; Types: custom; Flags: exclusive
Name: actions\dump; Description: "Toggle Saving Zend Server Process Dumps"; Types: custom; Flags: exclusive



[Code]

var
  InstallPath: String;
  ZSVersion: String;
  ApachePath: String;
//  TempDir: String;
  ArchiveName: String;
  Timestamp: String;
  WebServer: String;
  IsSQLite: Boolean;
  FreeMB, TotalMB: Cardinal;
  PasswdPage: TInputQueryWizardPage;
  ArchivePage: TInputDirWizardPage;
  ProgressPage: TOutputProgressWizardPage;
  Action: String;
  DBhost, DBport, DBname, DBuser, DBpw, LOrder, LKey: String;


function DirCopy (SourceDir, DestDir: String): Integer;
var
  RetCode: Integer;
begin
  Exec ('cmd.exe', '/c xcopy /h /e /q "' + SourceDir + '" "' + DestDir + '\"', '', SW_HIDE, ewWaitUntilTerminated, RetCode);
  Result := RetCode
end;


procedure InitializeWizard;
var
  ZSDBini: TArrayOfString;
begin

  Timestamp := GetDateTimeString('yy-mm-dd_hhnn', '-', '_');
  if RegValueExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Zend Technologies\ZendServer', 'InstallLocation') then
  begin
    RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Zend Technologies\ZendServer', 'InstallLocation', InstallPath);
  end;

  if RegValueExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Zend Technologies\ZendServer', 'Version') then
  begin
    RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Zend Technologies\ZendServer', 'Version', ZSVersion);
  end;

  if RegValueExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Zend Technologies\ZendServer', 'ApacheAppPort') then
  begin
    WebServer := 'Apache';
  end else begin
    WebServer := 'IIS';
  end;

  // workaround for missing sections in zend_database.ini
  LoadStringsFromFile(InstallPath + '\ZendServer\etc\zend_database.ini', ZSDBini);
  ZSDBini[0] := '[general]';
  SaveStringsToFile(ExpandConstant('{tmp}\zend_database.ini'), ZSDBini, False);

  IsSQLite := False;
  if (GetIniString('general', 'zend.database.type', '', ExpandConstant('{tmp}\zend_database.ini')) = 'SQLITE') then
  begin
    IsSQLite := True;
  end;

  // PageID 100
  ArchivePage := CreateInputDirPage(wpReady, 'Location of the Support Tool Archive', 'Where would you like to save the generated archive?',
    'Select the directory where the Support Tool archive will be saved.', False, '');
  ArchivePage.Add('');
  ArchivePage.Values[0] := ExpandConstant('{userdesktop}');

  // PageID 101 ?
  ProgressPage := CreateOutputProgressPage('Gathering Information', 'This may take several minutes');

  // PageID 102
  PasswdPage := CreateInputQueryPage(wpReady, 'Change "admin" Password', '', 'Enter the new password for the "admin" user');
  PasswdPage.Add('New Password:', False);

end;


procedure DeinitializeSetup;
begin
  if ( ArchiveName <> '' ) then begin
    MsgBox('The Support Tool archive was saved as:' + #13#10 + ArchiveName , mbInformation, MB_OK);
  end;
end;


function NextButtonClick(CurPageID: Integer): Boolean;

var
  cmdResult: Integer;
  OverviewText: String;

begin
    // MsgBox('CurPageID: ' + IntToStr(CurPageID) + #13#10 + 'Action: ' + Action, mbInformation, MB_OK);
  
  
  // Component Selection Page
  if (CurPageID = 7) then
  begin
    Action := '';

    // Actions
    if IsComponentSelected('actions') then
    begin

      // Simple Auth
      if IsComponentSelected('actions\simple') then
      begin
        if SetIniBool('authentication', 'zend_gui.simple', True, InstallPath + '\ZendServer\gui\config\zs_ui.ini') then
        begin
          MsgBox('Switched to simple authentication.', mbInformation, MB_OK);
        end else begin
          MsgBox('Switching to simple authentication failed.' + #13#10 + 'Please manually set the value' + #13#10 + '   zend_gui.simple = true' + #13#10 + 'in ' + InstallPath + '\ZendServer\gui\config\zs_ui.ini', mbError, MB_OK);
        end;
      end;

      // Change passwd
      if IsComponentSelected('actions\passwd') then
      begin
        Action := 'passwd';
      end;
    
      // Zend Server Stop / Start / Restart
      // Stop
      if IsComponentSelected('actions\services\stop') then
      begin
        if MsgBox('Do you want to stop Zend Server?', mbConfirmation, MB_YESNO) = IDYES then
        begin
            Exec (InstallPath + '\ZendServer\bin\ZendServer.bat', 'stop', InstallPath + '\ZendServer\bin', SW_SHOW, ewWaitUntilTerminated, cmdResult);
        end;
      end;
      // Start
      if IsComponentSelected('actions\services\start') then
      begin
          Exec (InstallPath + '\ZendServer\bin\ZendServer.bat', 'start', InstallPath + '\ZendServer\bin', SW_SHOW, ewWaitUntilTerminated, cmdResult);
      end;
      // Restart
      if IsComponentSelected('actions\services\restart') then
      begin
        if MsgBox('Do you want to restart Zend Server?', mbConfirmation, MB_YESNO) = IDYES then
        begin
            Exec (InstallPath + '\ZendServer\bin\ZendServer.bat', 'restart', InstallPath + '\ZendServer\bin', SW_SHOW, ewWaitUntilTerminated, cmdResult);
        end;
      end;

      // Configure Core Dumps
      if IsComponentSelected('actions\dump') then
      begin
        if RegKeyExists(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\zsd.exe') then
        begin
          if MsgBox('Disable saving Zend Server process dumps?', mbConfirmation, MB_YESNO) = IDYES then
          begin
            RegDeleteKeyIncludingSubkeys(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\php-cgi.exe');
            RegDeleteKeyIncludingSubkeys(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\php.exe');
            RegDeleteKeyIncludingSubkeys(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\jqd.exe');
            RegDeleteKeyIncludingSubkeys(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\MonitorNode.exe');
            RegDeleteKeyIncludingSubkeys(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\zsd.exe');
            RegDeleteKeyIncludingSubkeys(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\zdd.exe');
            RegDeleteKeyIncludingSubkeys(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\scd.exe');
          end;
        end else begin
          if MsgBox('Creating and saving dumps of Zend Server processes does not seem to be configured. Enable saving process dumps in "C:\Dumps"?', mbConfirmation, MB_YESNO) = IDYES then
          begin
            CreateDir ('C:\Dumps')
            RegWriteStringValue(HKLM64, 'Software\Microsoft\Windows NT\CurrentVersion\AeDebug', 'Auto', '0');

            RegWriteExpandStringValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\php-cgi.exe', 'DumpFolder', 'C:\Dumps');
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\php-cgi.exe', 'DumpCount', 5);
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\php-cgi.exe', 'DumpType', 2);

            RegWriteExpandStringValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\php.exe', 'DumpFolder', 'C:\Dumps');
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\php.exe', 'DumpCount', 5);
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\php.exe', 'DumpType', 2);

            RegWriteExpandStringValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\jqd.exe', 'DumpFolder', 'C:\Dumps');
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\jqd.exe', 'DumpCount', 5);
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\jqd.exe', 'DumpType', 2);

            RegWriteExpandStringValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\MonitorNode.exe', 'DumpFolder', 'C:\Dumps');
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\MonitorNode.exe', 'DumpCount', 5);
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\MonitorNode.exe', 'DumpType', 2);

            RegWriteExpandStringValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\zsd.exe', 'DumpFolder', 'C:\Dumps');
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\zsd.exe', 'DumpCount', 5);
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\zsd.exe', 'DumpType', 2);

            RegWriteExpandStringValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\zdd.exe', 'DumpFolder', 'C:\Dumps');
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\zdd.exe', 'DumpCount', 5);
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\zdd.exe', 'DumpType', 2);

            RegWriteExpandStringValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\scd.exe', 'DumpFolder', 'C:\Dumps');
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\scd.exe', 'DumpCount', 5);
            RegWriteDWordValue(HKLM64, 'Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\scd.exe', 'DumpType', 2);
          end;
        end;
      end;


    // Options
    end else begin
      Action := 'archive';
    end;
  end;  // if CurPageID = 7
  
  
  // Password Prompt Page
  if (CurPageID = 102) then
  begin
    if (Action = 'passwd') then
    begin
      if (PasswdPage.Values[0] = '') then
      begin
        MsgBox('The password cannot be empty', mbError, MB_OK);
      end else begin
        Exec (InstallPath + '\ZendServer\bin\php.exe', '"' + InstallPath + '\ZendServer\bin\gui_passwd.php" "' + PasswdPage.Values[0] + '"',
          InstallPath + '\ZendServer\bin', SW_HIDE, ewWaitUntilTerminated, cmdResult);
        MsgBox('Password change completed.' + #13#10 + '( exit status: ' + IntToStr(cmdResult) + ' )', mbInformation, MB_OK);
      end;
    end;
  end;  // if CurPageID = 102
  
  
  // Select Directory Page (create archive)
  if (CurPageID = 100) then
  begin
    if (Action = 'archive') then
    begin

      ProgressPage.SetProgress(0, 0);
      ProgressPage.Show;
      try
        
        // PREPARING
        ProgressPage.SetText('Preparing...', '');
        ProgressPage.SetProgress(1, 10);

        ArchiveName := ArchivePage.Values[0] +  '\ZS9ST_' + ZSVersion + '_' + Timestamp + '.7z';
        
        CreateDir (ExpandConstant('{tmp}\ZS9ST_Files'));

        ExtractTemporaryFiles('{tmp}\*.*');


        // PHPINFO
        ProgressPage.SetText('Getting phpinfo()...', '');
        ProgressPage.SetProgress(2, 10);

        Exec (ExpandConstant('{tmp}\curl.exe'),
          '-sLo phpinfo_main.html http://127.0.0.1:10083/zsd_php_info.php',
          ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);
        
        Exec (InstallPath + '\ZendServer\bin\php.exe',
          '-nr "$info=json_decode(file_get_contents(\"phpinfo_main.html\"), true); file_put_contents(\"real_phpinfo_main.html\",$info[\"phpinfo\"]);"',
          ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);

        RenameFile (ExpandConstant('{tmp}\real_phpinfo_main.html'), ExpandConstant('{tmp}\ZS9ST_Files\phpinfo.html'));
        

        // CONFIGS AND LOGS
        ProgressPage.SetText('Getting configuration and logs - ' + WebServer + '...', '');
        ProgressPage.SetProgress(3, 10);

        if ( WebServer = 'Apache' ) then
        begin
          
          // to maintain compatibility with ZS 6-8
          if (DirExists (InstallPath + '\Apache2')) then
          begin
            ApachePath := InstallPath + '\Apache2';
          end else begin
            ApachePath := InstallPath + '\Apache24';
          end;
          
          DirCopy (ApachePath +'\conf', ExpandConstant('{tmp}\ZS9ST_Files\apache_config'));
          DirCopy (ApachePath +'\logs', ExpandConstant('{tmp}\ZS9ST_Files\apache_logs'));  
        end else begin
          //DirCopy (ExpandConstant('{sys}\inetsrv\config'), ExpandConstant('{tmp}\ZS9ST_Files\iis_config'));
          CreateDir (ExpandConstant('{tmp}\ZS9ST_Files\iis_config'));
          Exec ('cmd', '/c ' + ExpandConstant('{sys}\inetsrv\appcmd.exe list config /text:*') + ' > "' + ExpandConstant('{tmp}\ZS9ST_Files\iis_config\CONFIG.txt') + '"',
            ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);
          Exec ('cmd', '/c ' + ExpandConstant('{sys}\inetsrv\appcmd.exe list apppool /text:*') + ' > "' + ExpandConstant('{tmp}\ZS9ST_Files\iis_config\APPOOL.txt') + '"',
            ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);
          Exec ('cmd', '/c ' + ExpandConstant('{sys}\inetsrv\appcmd.exe list app /text') + ' > "' + ExpandConstant('{tmp}\ZS9ST_Files\iis_config\summary.txt') + '"',
            ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);
          Exec ('cmd', '/c ' + ExpandConstant('{sys}\inetsrv\appcmd.exe list vdir /text') + ' >> "' + ExpandConstant('{tmp}\ZS9ST_Files\iis_config\summary.txt') + '"',
            ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);
          Exec ('cmd', '/c ' + ExpandConstant('{sys}\inetsrv\appcmd.exe list site /text') + ' >> "' + ExpandConstant('{tmp}\ZS9ST_Files\iis_config\summary.txt') + '"',
            ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);

          DirCopy (ExpandConstant('{sd}\inetpub\logs\LogFiles'), ExpandConstant('{tmp}\ZS9ST_Files\iis_logs'));
          DirCopy (ExpandConstant('{sys}\LogFiles\HTTPERR'), ExpandConstant('{tmp}\ZS9ST_Files\iis_logs\HTTPERR'));
        end;

        ProgressPage.SetProgress(4, 10);
        ProgressPage.SetText('Getting configuration and logs - Zend Server...', '');

        DirCopy (InstallPath + '\ZendServer\etc', ExpandConstant('{tmp}\ZS9ST_Files\zend_etc'));
        DirCopy (InstallPath + '\ZendServer\gui\config', ExpandConstant('{tmp}\ZS9ST_Files\gui_config'));

        if IsComponentSelected('options\full') then
        begin
          DirCopy (InstallPath + '\ZendServer\logs', ExpandConstant('{tmp}\ZS9ST_Files\zend_logs'));
        end else begin
          ProgressPage.SetText('Getting configuration and logs - Zend Server...', '');
          Exec (InstallPath + '\ZendServer\bin\php.exe',
            '-n "' + ExpandConstant('{tmp}\list_logs.php') + '" 1000 "' + InstallPath + '\ZendServer\logs\*.log" "' + ExpandConstant('{tmp}\ZS9ST_Files\zend_logs') + '"',
            '', SW_HIDE, ewWaitUntilTerminated, cmdResult);
        end;


        // ZS INFO
        ProgressPage.SetProgress(5, 10);
        ProgressPage.SetText('Getting Zend Server information...', '');
        
        Exec (ExpandConstant('{tmp}\zs.cmd'),
          '"' + InstallPath + '\ZendServer" "' + ExpandConstant('{tmp}\ZS9ST_Files') + '"',
          ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);

        // get SQLite DBs
        if IsComponentSelected('options\sqlite') then
        begin
          if IsSQLite then
          begin
            ProgressPage.SetText('Getting SQLite databases...', '');
            DirCopy (InstallPath + '\ZendServer\data\db', ExpandConstant('{tmp}\ZS9ST_Files\zs_sqlite'));
          end else begin
            MsgBox('This server appears to be part of a cluster. Although you chose to add the SQLite databses to the archive, they will not be included.', mbInformation, MB_OK);
          end;
        end;

        // DBs INFO                 
        ProgressPage.SetProgress(5, 10);
        ProgressPage.SetText('Getting information about internal databases...', '');

        if (GetIniString('general', 'zend.database.type', '', ExpandConstant('{tmp}\zend_database.ini')) = 'SQLITE') then
        begin
          // sqlite stuff                                                             
        end else begin
          if (GetIniString('general', 'zend.database.type', '', ExpandConstant('{tmp}\zend_database.ini')) = 'MYSQL') then
          begin
            DBhost := GetIniString('general', 'zend.database.host_name', '', ExpandConstant('{tmp}\zend_database.ini'));
            DBport := GetIniString('general', 'zend.database.port', '', ExpandConstant('{tmp}\zend_database.ini'));
            DBname := GetIniString('general', 'zend.database.name', '', ExpandConstant('{tmp}\zend_database.ini'));
            DBuser := GetIniString('general', 'zend.database.user', '', ExpandConstant('{tmp}\zend_database.ini'));
            DBpw := GetIniString('general', 'zend.database.password', '', ExpandConstant('{tmp}\zend_database.ini'));

            CreateDir (ExpandConstant('{tmp}\ZS9ST_Files\zs_mysql'));

            Exec (InstallPath + '\ZendServer\bin\php.exe',
              '-n -d "extension=''' + InstallPath + '\ZendServer\lib\phpext\php_mysqli.dll''" -f ' + ExpandConstant('{tmp}\mysql.php') + ' ' +
              DBhost + ' ' + DBport + ' ' + DBname + ' ' + DBuser + ' "' + DBpw + '" "' + ExpandConstant('{tmp}\ZS9ST_Files\zs_mysql\mysql_info.html') + '"',
              InstallPath + '\ZendServer\bin', SW_HIDE, ewWaitUntilTerminated, cmdResult);
          end;
        end;


        // SYSTEM INFO
        ProgressPage.SetProgress(7, 10);
        ProgressPage.SetText('Getting system information...', '');
        
        Exec (ExpandConstant('{tmp}\sys.cmd'),
          '"' + InstallPath + '\ZendServer" "' + ExpandConstant('{tmp}\ZS9ST_Files') + '"',
          ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);


        // OVERVIEW
        ProgressPage.SetProgress(8, 10);
        ProgressPage.SetText('Creating short summary...', '');
        if IsWin64 then
        begin
          OverviewText := 'Microsoft Windows 64-bit, ver. ' + GetWindowsVersionString() + #13#10 ;
        end else begin
          OverviewText := 'Microsoft Windows 32bit, ver. ' + GetWindowsVersionString() + #13#10 ;
        end;

        OverviewText := OverviewText + 'Zend Server ver. ' + GetIniString('package', 'zend_gui.version', '', InstallPath + '\ZendServer\etc\packaging.ini');
        OverviewText := OverviewText + '-' + GetIniString('package', 'zend_gui.zs_upgrade', '', InstallPath + '\ZendServer\etc\packaging.ini');
        OverviewText := OverviewText + ' GUI build ' + GetIniString('package', 'zend_gui.build', '', InstallPath + '\ZendServer\etc\packaging.ini');
        OverviewText := OverviewText + #13#10 ;

        OverviewText := OverviewText + 'Web Server: ' + WebServer;
        OverviewText := OverviewText + ',  PHP Version: ';
        SaveStringToFile(ExpandConstant('{tmp}\ZS9ST_Files\overview.txt'), OverviewText, True);

        Exec (InstallPath + '\ZendServer\bin\php.exe',
          '-nr "file_put_contents (\"' + ExpandConstant('{tmp}\ZS9ST_Files\overview.txt') +'\" , phpversion(), FILE_APPEND);"',
          ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);
        

        OverviewText := #13#10#13#10 ;
        
        OverviewText := OverviewText + 'Computer Name: ' + ExpandConstant('{computername}') + #13#10 ;

        GetSpaceOnDisk(ExpandConstant('{tmp}'), True, FreeMB, TotalMB);
        OverviewText := OverviewText + 'Space on TEMP disk: ' + IntToStr(FreeMB) + 'MB out of ' + IntToStr(TotalMB) + 'MB total' + #13#10 ;

        GetSpaceOnDisk(InstallPath, True, FreeMB, TotalMB);
        OverviewText := OverviewText + 'Space on ZS disk: ' + IntToStr(FreeMB) + 'MB out of ' + IntToStr(TotalMB) + 'MB total' + #13#10 ;

        // GetSpaceOnDisk('C:\', True, FreeMB, TotalMB);
        // OverviewText := OverviewText + 'Space disk C: ' + IntToStr(FreeMB) + 'MB out of ' + IntToStr(TotalMB) + 'MB total' + #13#10 ;

        SaveStringToFile(ExpandConstant('{tmp}\ZS9ST_Files\overview.txt'), OverviewText, True);

        // License information
        LOrder := GetIniString('Zend', 'zend.user_name', '', InstallPath + '\ZendServer\etc\php.ini');
        LKey := GetIniString('Zend', 'zend.serial_number', '', InstallPath + '\ZendServer\etc\php.ini');
        Exec ('cmd', '/c ' + GetShortName(InstallPath + '\ZendServer\bin\php-cgi.exe') + ' -c "' + InstallPath + '\ZendServer\etc\php.ini" -f "' + ExpandConstant('{tmp}\checLic.php') + '" o=' + LOrder + ' k=' + LKey + ' >> "' + ExpandConstant('{tmp}\ZS9ST_Files\overview.txt') + '"',
          ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);

        // PACKING  
        ProgressPage.SetText('Creating archive...', '');
        ProgressPage.SetProgress(9, 10);

        Exec (ExpandConstant('{tmp}\7z.exe'),
          'a "' +  ArchiveName + '" "' + ExpandConstant('{tmp}\ZS9ST_Files') + '"',
          ExpandConstant('{tmp}'), SW_HIDE, ewWaitUntilTerminated, cmdResult);


      
        // DONE  
        ProgressPage.SetText('Done.', '');
        ProgressPage.SetProgress(10, 10);

        Sleep(1000);
      
      finally
        ProgressPage.Hide;
      end;
    end;   // if Action = 'archive'
  end;   // if CurPageID = 7
  Result := True;
end;   // NextButtonClick()


function ShouldSkipPage (PageID: Integer): Boolean;
begin

  Result := True

  if (PageID = 7) then
  begin
    Result := False;
  end;


  if (PageID = 100) then
  begin
    if (Action = 'archive') then
    begin
      Result := False;
    end;
  end;


  if (PageID = 102) then
  begin
    if (Action = 'passwd') then
    begin
      Result := False;
    end;
  end;

end;

  //    MsgBox('TMP Dir: ' + ExpandConstant('{tmp}'), mbInformation, MB_OK);
