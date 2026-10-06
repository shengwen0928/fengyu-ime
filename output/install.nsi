; fengyu installation script
!include FileFunc.nsh
!include LogicLib.nsh
!include MUI2.nsh
!include x64.nsh
!include winVer.nsh

Unicode true

;--------------------------------
; General

!ifndef FENGYU_VERSION
!define FENGYU_VERSION 0.1.0
!endif

!ifndef FENGYU_BUILD
!define FENGYU_BUILD 0
!endif

!define FENGYU_ROOT $INSTDIR\fengyu-${FENGYU_VERSION}
!define REG_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\Fengyu"

; The name of the installer
Name "風語輸入法 ${FENGYU_VERSION}"

; The file to write
OutFile "archives\fengyu-ime-${PRODUCT_VERSION}-installer.exe"

VIProductVersion "${FENGYU_VERSION}.${FENGYU_BUILD}"
VIAddVersionKey /LANG=2052 "ProductName" "風語輸入法"
VIAddVersionKey /LANG=2052 "Comments" "AIW 風光Ai窗"
VIAddVersionKey /LANG=2052 "CompanyName" "AIW 風光Ai窗"
VIAddVersionKey /LANG=2052 "LegalCopyright" "AIW 風光Ai窗"
VIAddVersionKey /LANG=2052 "FileDescription" "風語輸入法"
VIAddVersionKey /LANG=2052 "FileVersion" "${FENGYU_VERSION}"

!define MUI_ICON ..\resource\fengyu.ico
!define MUI_UNICON ..\resource\fengyu.ico
SetCompressor /SOLID lzma


; Request application privileges for Windows Vista
RequestExecutionLevel admin

;--------------------------------

; Pages

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------

; Languages

!insertmacro MUI_LANGUAGE "TradChinese"
LangString DISPLAYNAME ${LANG_TRADCHINESE} "風語輸入法"
LangString LNKFORMANUAL ${LANG_TRADCHINESE} "【風語輸入法】說明書"
LangString LNKFORSETTING ${LANG_TRADCHINESE} "【風語輸入法】輸入法設定"
LangString LNKFORDICT ${LANG_TRADCHINESE} "【風語輸入法】用戶詞典管理"
LangString LNKFORSYNC ${LANG_TRADCHINESE} "【風語輸入法】用戶資料同步"
LangString LNKFORDEPLOY ${LANG_TRADCHINESE} "【風語輸入法】重新部署"
LangString LNKFORSERVER ${LANG_TRADCHINESE} "風語輸入法算法服務"
LangString LNKFORUSERFOLDER ${LANG_TRADCHINESE} "【風語輸入法】用戶文件夾"
LangString LNKFORAPPFOLDER ${LANG_TRADCHINESE} "【風語輸入法】程序文件夾"
LangString LNKFORUPDATER ${LANG_TRADCHINESE} "【風語輸入法】檢查新版本"
LangString LNKFORSETUP ${LANG_TRADCHINESE} "【風語輸入法】安裝選項"
LangString LNKFORUNINSTALL ${LANG_TRADCHINESE} "卸載風語輸入法"
LangString CONFIRMATION ${LANG_TRADCHINESE} "安裝前，請先卸載舊版本的風語輸入法。$\n$\n按下「確定」移除舊版本，按下「取消」放棄本次安裝。"
LangString SYSTEMVERSIONNOTOK ${LANG_TRADCHINESE} "您的系统不被支持，最低系統要求:Windows 8.1!"
LangString AUTOCHKUPDATE ${LANG_TRADCHINESE} "自動檢查版本更新？"

!insertmacro MUI_LANGUAGE "SimpChinese"
LangString DISPLAYNAME ${LANG_SIMPCHINESE} "風語輸入法"
LangString LNKFORMANUAL ${LANG_SIMPCHINESE} "【風語輸入法】说明书"
LangString LNKFORSETTING ${LANG_SIMPCHINESE} "【風語輸入法】输入法设定"
LangString LNKFORDICT ${LANG_SIMPCHINESE} "【風語輸入法】用户词典管理"
LangString LNKFORSYNC ${LANG_SIMPCHINESE} "【風語輸入法】用户资料同步"
LangString LNKFORDEPLOY ${LANG_SIMPCHINESE} "【風語輸入法】重新部署"
LangString LNKFORSERVER ${LANG_SIMPCHINESE} "風語輸入法算法服务"
LangString LNKFORUSERFOLDER ${LANG_SIMPCHINESE} "【風語輸入法】用户文件夹"
LangString LNKFORAPPFOLDER ${LANG_SIMPCHINESE} "【風語輸入法】程序文件夹"
LangString LNKFORUPDATER ${LANG_SIMPCHINESE} "【風語輸入法】检查新版本"
LangString LNKFORSETUP ${LANG_SIMPCHINESE} "【風語輸入法】安装选项"
LangString LNKFORUNINSTALL ${LANG_SIMPCHINESE} "卸载風語輸入法"
LangString CONFIRMATION ${LANG_SIMPCHINESE} '安装前，请先卸载旧版本的風語輸入法。$\n$\n点击 "确定" 移除旧版本，或点击 "取消" 放弃本次安装。'
LangString SYSTEMVERSIONNOTOK ${LANG_SIMPCHINESE} "您的系統不被支持，最低系统要求:Windows 8.1!"
LangString AUTOCHKUPDATE ${LANG_SIMPCHINESE} "自动检查版本更新？"

!insertmacro MUI_LANGUAGE "English"
LangString DISPLAYNAME ${LANG_ENGLISH} "Fengyu"
LangString LNKFORMANUAL ${LANG_ENGLISH} "Fengyu Manual"
LangString LNKFORSETTING ${LANG_ENGLISH} "Fengyu Settings"
LangString LNKFORDICT ${LANG_ENGLISH} "Fengyu Dictionary Manager"
LangString LNKFORSYNC ${LANG_ENGLISH} "Fengyu Sync User Profile"
LangString LNKFORDEPLOY ${LANG_ENGLISH} "Fengyu Deploy"
LangString LNKFORSERVER ${LANG_ENGLISH} "Fengyu Server"
LangString LNKFORUSERFOLDER ${LANG_ENGLISH} "Fengyu User Folder"
LangString LNKFORAPPFOLDER ${LANG_ENGLISH} "Fengyu App Folder"
LangString LNKFORUPDATER ${LANG_ENGLISH} "Fengyu Check for Updates"
LangString LNKFORSETUP ${LANG_ENGLISH} "Fengyu Installation Preference"
LangString LNKFORUNINSTALL ${LANG_ENGLISH} "Uninstall Fengyu"
LangString CONFIRMATION ${LANG_ENGLISH} "Before installation, please uninstall the old version of Fengyu.$\n$\nPress 'OK' to remove the old version, or 'Cancel' to abort installation."
LangString SYSTEMVERSIONNOTOK ${LANG_ENGLISH} "Your system not supported, minimium system required: Windows 8.1!"
LangString AUTOCHKUPDATE ${LANG_ENGLISH} "Automatically check for updates?"

;--------------------------------

; Remove an old Fengyu IME release that still used the upstream Weasel/Rime
; names (installed under Program Files\Rime), then copy its user data
; (learned words and UI settings) from %APPDATA%\Rime to %APPDATA%\Fengyu.
; Only acts when the old entry was published by us, so a genuine upstream
; installation is never touched.
Function RemoveLegacyFengyu
  ReadRegStr $R2 HKLM \
  "Software\Microsoft\Windows\CurrentVersion\Uninstall\Weasel" "Publisher"
  StrCmp $R2 "AIW 風光Ai窗" 0 legacy_done
  ReadRegStr $R3 HKLM "SOFTWARE\Rime\Weasel" "WeaselRoot"
  StrCmp $R3 "" legacy_done

  IfSilent legacy_remove 0
  MessageBox MB_OKCANCEL|MB_ICONINFORMATION "$(CONFIRMATION)" IDOK legacy_remove
  Abort

legacy_remove:
  ExecWait '"$R3\WeaselServer.exe" /quit'
  ExecWait '"$R3\WeaselSetup.exe" /u'
  DeleteRegKey HKLM "SOFTWARE\Rime\Weasel"
  DeleteRegKey /ifempty HKLM "SOFTWARE\Rime"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Weasel"
  ${If} ${IsNativeARM64}
    SetRegView 64
  ${ElseIf} ${IsNativeAMD64}
    SetRegView 64
  ${Endif}
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "WeaselServer"
  SetRegView 32
  Delete /REBOOTOK "$R3\data\opencc\*.*"
  Delete /REBOOTOK "$R3\data\preview\*.*"
  Delete /REBOOTOK "$R3\data\lua\*.*"
  Delete /REBOOTOK "$R3\data\*.*"
  Delete /REBOOTOK "$R3\Win32\*.*"
  Delete /REBOOTOK "$R3\*.*"
  RMDir /REBOOTOK "$R3\data\opencc"
  RMDir /REBOOTOK "$R3\data\preview"
  RMDir /REBOOTOK "$R3\data\lua"
  RMDir /REBOOTOK "$R3\data"
  RMDir /REBOOTOK "$R3\Win32"
  RMDir /REBOOTOK "$R3"
  RMDir "$R3\.."
  SetShellVarContext all
  Delete "$SMPROGRAMS\$(DISPLAYNAME)\*.*"
  RMDir "$SMPROGRAMS\$(DISPLAYNAME)"

  ; per-user settings and data of the old release
  SetShellVarContext current
  DeleteRegKey HKCU "Software\Rime\Weasel"
  DeleteRegKey /ifempty HKCU "Software\Rime"
  IfFileExists "$APPDATA\Fengyu\*.*" legacy_reboot
  IfFileExists "$APPDATA\Rime\fengyu.userdb\*.*" 0 legacy_reboot
  CreateDirectory "$APPDATA\Fengyu"
  CopyFiles /SILENT "$APPDATA\Rime\*.userdb" "$APPDATA\Fengyu"
  CopyFiles /SILENT "$APPDATA\Rime\default.custom.yaml" "$APPDATA\Fengyu"
  CopyFiles /SILENT "$APPDATA\Rime\user.yaml" "$APPDATA\Fengyu"
  CopyFiles /SILENT "$APPDATA\Rime\weasel.custom.yaml" "$APPDATA\Fengyu\fengyu.custom.yaml"

legacy_reboot:
  SetShellVarContext all
  SetRebootFlag true
  Sleep 800

legacy_done:
FunctionEnd

Function .onInit
  ; if not version >= 8.1, quit and MessageBox(if not silent)
  ${IfNot} ${AtLeastWin8.1}
    IfSilent toquit
    MessageBox MB_OK '$(SYSTEMVERSIONNOTOK)'
toquit:
    Quit
  ${EndIf}

  Call RemoveLegacyFengyu

  ReadRegStr $R0 HKLM "Software\Fengyu\IME" "InstallDir"
  StrCmp $R0 "" 0 skip
  ; The default installation directory
  ; install x64 build for NativeARM64_WINDOWS11 and NativeAMD64_WINDOWS11
  ${If} ${AtLeastWin11} ; Windows 11 and above
    ${If} ${IsNativeARM64}
      StrCpy $INSTDIR "$PROGRAMFILES64\Fengyu"
    ${ElseIf} ${IsNativeAMD64}
      StrCpy $INSTDIR "$PROGRAMFILES64\Fengyu"
    ${Else}
      StrCpy $INSTDIR "$PROGRAMFILES\Fengyu"
    ${Endif}
  ; install x64 build for NativeAMD64_BELLOW_WINDOWS11
  ${Else} ; Windows 10 or bellow
    ${If} ${IsNativeAMD64}
      StrCpy $INSTDIR "$PROGRAMFILES64\Fengyu"
    ${Else}
      StrCpy $INSTDIR "$PROGRAMFILES\Fengyu"
    ${Endif}
  ${Endif}
skip:
  ReadRegStr $R0 HKLM \
  "Software\Microsoft\Windows\CurrentVersion\Uninstall\Fengyu" \
  "UninstallString"
  StrCmp $R0 "" done

  StrCpy $0 "Upgrade"
  IfSilent uninst 0
  MessageBox MB_OKCANCEL|MB_ICONINFORMATION "$(CONFIRMATION)" IDOK uninst
  Abort

uninst:
  ; Backup data directory from previous installation, user files may exist
  ReadRegStr $R1 HKLM SOFTWARE\Fengyu\IME "FengyuRoot"
  StrCmp $R1 "" call_uninstaller
  IfFileExists $R1\data\*.* 0 call_uninstaller
  CreateDirectory $TEMP\fengyu-backup
  CopyFiles $R1\data\*.* $TEMP\fengyu-backup

call_uninstaller:
  ExecWait '"$R1\FengyuServer.exe" /quit'
  ExecWait '"$R1\FengyuSetup.exe" /u'
  ; Remove registry keys
  DeleteRegKey HKLM SOFTWARE\Fengyu
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Fengyu"
  ; don't redirect on 64 bit system for auto run setting
  ${If} ${IsNativeARM64}
    SetRegView 64
  ${ElseIf} ${IsNativeAMD64}
    SetRegView 64
  ${Endif}
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "FengyuServer"
  ; recover back to 32bit view
  SetRegView 32
  ; Remove files and uninstaller
  Delete  "$R1\data\opencc\*.*"
  Delete  "$R1\data\preview\*.*"
  Delete  "$R1\data\lua\*.*"
  Delete  "$R1\data\*.*"
  Delete  "$R1\*.*"
  RMDir   "$R1\data\opencc"
  RMDir   "$R1\data\preview"
  RMDir   "$R1\data\lua"
  RMDir   "$R1\data"
  RMDir   "$R1"
  SetShellVarContext all
  Delete  "$SMPROGRAMS\$(DISPLAYNAME)\*.*"
  RMDir  "$SMPROGRAMS\$(DISPLAYNAME)"
  ; Prompt reboot
  SetRebootFlag true
  Sleep 800

done:
FunctionEnd

; Registry key to check for directory (so if you install again, it will
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\Fengyu\IME" "InstallDir"

; The stuff to install
Section "Fengyu"

  SectionIn RO

  ; Write the new installation path into the registry
  ; redirect on 64 bit system
  ; HKLM SOFTWARE\WOW6432Node\Fengyu\IME "InstallDir" "$INSTDIR"
  WriteRegStr HKLM SOFTWARE\Fengyu\IME "InstallDir" "$INSTDIR"

  ; Reset INSTDIR for the new version
  StrCpy $INSTDIR "${FENGYU_ROOT}"

  IfFileExists "$INSTDIR\FengyuServer.exe" 0 +2
  ExecWait '"$INSTDIR\FengyuServer.exe" /quit'

  SetOverwrite try
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR

  IfFileExists $TEMP\fengyu-backup\*.* 0 program_files
  CreateDirectory $INSTDIR\data
  CopyFiles $TEMP\fengyu-backup\*.* $INSTDIR\data
  RMDir /r $TEMP\fengyu-backup

program_files:
  File "README.txt"
  File "start_service.bat"
  File "stop_service.bat"
  File "fengyu.dll"
  ${If} ${RunningX64}
    File "fengyux64.dll"
  ${EndIf}
  ${If} ${IsNativeARM64}
    File /nonfatal "fengyuARM.dll"
    File /nonfatal "fengyuARM64.dll"
    File /nonfatal "fengyuARM64X.dll"
  ${EndIf}
  File "fengyu.ime"
  ${If} ${RunningX64}
    File "fengyux64.ime"
  ${EndIf}
  ${If} ${IsNativeARM64}
    File /nonfatal "fengyuARM.ime"
    File /nonfatal "fengyuARM64.ime"
    File /nonfatal "fengyuARM64X.ime"
  ${EndIf}
  ; install x64 build for NativeARM64_WINDOWS11 and NativeAMD64_WINDOWS11
  ${If} ${AtLeastWin11} ; Windows 11 and above
    ${If} ${IsNativeARM64}
      File "FengyuDeployer.exe"
      File "FengyuServer.exe"
      File "fengyucore.dll"
      File "WinSparkle.dll"
    ${ElseIf} ${IsNativeAMD64}
      File "FengyuDeployer.exe"
      File "FengyuServer.exe"
      File "fengyucore.dll"
      File "WinSparkle.dll"
    ${Else}
      File "Win32\FengyuDeployer.exe"
      File "Win32\FengyuServer.exe"
      File "Win32\fengyucore.dll"
      File "Win32\WinSparkle.dll"
    ${Endif}
  ; install x64 build for NativeAMD64_BELLOW_WINDOWS11
  ${Else} ; Windows 10 or bellow
    ${If} ${IsNativeAMD64}
      File "FengyuDeployer.exe"
      File "FengyuServer.exe"
      File "fengyucore.dll"
      File "WinSparkle.dll"
    ${Else}
      File "Win32\FengyuDeployer.exe"
      File "Win32\FengyuServer.exe"
      File "Win32\fengyucore.dll"
      File "Win32\WinSparkle.dll"
    ${Endif}
  ${Endif}

  File "FengyuSetup.exe"
  ; shared data files
  SetOutPath $INSTDIR\data
  File "data\*.yaml"
  File /nonfatal "data\*.txt"
  File /nonfatal "data\*.gram"
  ; opencc data files
  SetOutPath $INSTDIR\data\opencc
  File "data\opencc\*.json"
  File "data\opencc\*.ocd*"
  ; images
  SetOutPath $INSTDIR\data\preview
  File "data\preview\*.png"
  ; fengyu lua scripts (mixed zhuyin/english input)
  SetOutPath $INSTDIR\data\lua
  File "data\lua\*.lua"

  SetOutPath $INSTDIR

  ; test /T flag for zh_TW locale
  StrCpy $R2 "/i"
  ${GetParameters} $R0
  ClearErrors
  ${GetOptions} $R0 "/S" $R1
  IfErrors +2 0
  StrCpy $R2 "/s"
  ${GetOptions} $R0 "/T" $R1
  IfErrors +2 0
  StrCpy $R2 "/t"

  ExecWait '"$INSTDIR\FengyuSetup.exe" $R2'

  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "${REG_UNINST_KEY}" "DisplayName" "$(DISPLAYNAME)"
  WriteRegStr HKLM "${REG_UNINST_KEY}" "DisplayIcon" '"$INSTDIR\FengyuServer.exe"'
  WriteRegStr HKLM "${REG_UNINST_KEY}" "DisplayVersion" "${FENGYU_VERSION}.${FENGYU_BUILD}"
  WriteRegStr HKLM "${REG_UNINST_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "${REG_UNINST_KEY}" "Publisher" "AIW 風光Ai窗"
  WriteRegDWORD HKLM "${REG_UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${REG_UNINST_KEY}" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; run as user...
  IfSilent deploy_silently
  ExecWait "$INSTDIR\FengyuDeployer.exe /install"
  GoTo deploy_done

  deploy_silently:
  ExecWait "$INSTDIR\FengyuDeployer.exe /deploy"
  deploy_done:

  ; don't redirect on 64 bit system for auto run setting
  ${If} ${IsNativeARM64}
    SetRegView 64
  ${ElseIf} ${IsNativeAMD64}
    SetRegView 64
  ${Endif}
  ; Write autorun key
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "FengyuServer" "$INSTDIR\FengyuServer.exe"
  ; Start FengyuServer
  Exec "$INSTDIR\FengyuServer.exe"

  ; option CheckForUpdates
  IfSilent DisableAutoCheckUpdate
  MessageBox MB_YESNO|MB_ICONINFORMATION "$(AUTOCHKUPDATE)" IDYES EnableAutoCheckUpdate
  DisableAutoCheckUpdate:
  WriteRegStr HKCU "Software\Fengyu\IME\Updates" "CheckForUpdates" "0"
  GoTo end
  EnableAutoCheckUpdate:
  WriteRegStr HKCU "Software\Fengyu\IME\Updates" "CheckForUpdates" "1"
  end:

  ; Prompt reboot
  StrCmp $0 "Upgrade" 0 +2
  SetRebootFlag true

SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"
  SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\$(DISPLAYNAME)"
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORMANUAL).lnk" "$INSTDIR\README.txt"
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORSETTING).lnk" "$INSTDIR\FengyuDeployer.exe" "" "$SYSDIR\shell32.dll" 21
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORDICT).lnk" "$INSTDIR\FengyuDeployer.exe" "/dict" "$SYSDIR\shell32.dll" 6
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORSYNC).lnk" "$INSTDIR\FengyuDeployer.exe" "/sync" "$SYSDIR\shell32.dll" 26
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORDEPLOY).lnk" "$INSTDIR\FengyuDeployer.exe" "/deploy" "$SYSDIR\shell32.dll" 144
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORSERVER).lnk" "$INSTDIR\FengyuServer.exe" "" "$INSTDIR\FengyuServer.exe" 0
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORUSERFOLDER).lnk" "$INSTDIR\FengyuServer.exe" "/userdir" "$SYSDIR\shell32.dll" 126
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORAPPFOLDER).lnk" "$INSTDIR\FengyuServer.exe" "/fengyudir" "$SYSDIR\shell32.dll" 19
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORUPDATER).lnk" "$INSTDIR\FengyuServer.exe" "/update" "$SYSDIR\shell32.dll" 13
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORSETUP).lnk" "$INSTDIR\FengyuSetup.exe" "" "$SYSDIR\shell32.dll" 162
  CreateShortCut "$SMPROGRAMS\$(DISPLAYNAME)\$(LNKFORUNINSTALL).lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"

  ExecWait '"$INSTDIR\FengyuServer.exe" /quit'

  ExecWait '"$INSTDIR\FengyuSetup.exe" /u'

  ; Remove registry keys
  DeleteRegKey HKLM SOFTWARE\Fengyu
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Fengyu"
  ; don't redirect on 64 bit system for auto run setting
  ${If} ${IsNativeARM64}
    SetRegView 64
  ${ElseIf} ${IsNativeAMD64}
    SetRegView 64
  ${Endif}
  DeleteRegValue HKLM "Software\Microsoft\Windows\CurrentVersion\Run" "FengyuServer"

  ; Remove files and uninstaller
  SetOutPath $TEMP
  Delete  "$INSTDIR\data\opencc\*.*"
  Delete  "$INSTDIR\data\preview\*.*"
  Delete  "$INSTDIR\data\lua\*.*"
  Delete  "$INSTDIR\data\*.*"
  Delete  "$INSTDIR\*.*"
  RMDir  "$INSTDIR\data\opencc"
  RMDir  "$INSTDIR\data\preview"
  RMDir  "$INSTDIR\data\lua"
  RMDir  "$INSTDIR\data"
  RMDir  "$INSTDIR"
  SetShellVarContext all
  Delete  "$SMPROGRAMS\$(DISPLAYNAME)\*.*"
  RMDir  "$SMPROGRAMS\$(DISPLAYNAME)"

  ; Prompt reboot
  SetRebootFlag true

SectionEnd
