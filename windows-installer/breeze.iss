; Breeze Windows 安装器（Inno Setup 7）
;
; 由 script/build/build_windows.dart 调用：
;   ISCC.exe -dAppVersion=... -dVersionQuad=... -dStageDir=... -dOutputDir=... breeze.iss
;
; 手动编译（需先构建 Flutter Windows Release）：
;   "%ProgramFiles%\Inno Setup 7\ISCC.exe" windows-installer\breeze.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#ifndef VersionQuad
  #define VersionQuad "0.0.0.0"
#endif

#ifndef StageDir
  #define StageDir "..\build\windows\x64\runner\Release"
#endif

#ifndef OutputDir
  #define OutputDir "..\build\windows\installer"
#endif

[Setup]
AppId={{B7E3D0F4-6C1A-4F3E-9B2A-8D5C7E1F4A60}
AppName=Breeze
AppVersion={#AppVersion}
AppVerName=Breeze v{#AppVersion}
AppPublisher=Breeze
AppPublisherURL=https://github.com/deretame/Breeze
AppSupportURL=https://github.com/deretame/Breeze/issues
AppUpdatesURL=https://github.com/deretame/Breeze/releases
DefaultDirName={code:GetDefaultDir}
DefaultGroupName=Breeze
DisableProgramGroupPage=yes
UsePreviousAppDir=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=windows-installer
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\Release\zephyr.exe
UninstallDisplayName=Breeze
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern dynamic
ShowLanguageDialog=yes
LanguageDetectionMethod=uilanguage
CloseApplications=no
RestartApplications=no
VersionInfoCompany=Breeze
VersionInfoDescription=Breeze 安装程序
VersionInfoProductName=Breeze
VersionInfoProductVersion={#VersionQuad}
VersionInfoTextVersion={#AppVersion}
VersionInfoVersion={#VersionQuad}

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}\Release"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{userprograms}\Breeze"; Filename: "{app}\Release\zephyr.exe"; WorkingDir: "{app}\Release"
Name: "{userdesktop}\Breeze"; Filename: "{app}\Release\zephyr.exe"; WorkingDir: "{app}\Release"; Tasks: desktopicon

[Run]
Filename: "{app}\Release\zephyr.exe"; WorkingDir: "{app}\Release"; Description: "{cm:LaunchProgram,Breeze}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; 与旧安装器一致：卸载时删除整个安装目录
Type: filesandordirs; Name: "{app}"
; 旧 Tauri 安装器留下的路径记录文件
Type: files; Name: "{localappdata}\breeze-install-log.json"

[Code]
const
  LEGACY_UNINSTALL_KEY =
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\Breeze';

// 去掉尾部分隔符，避免应用目录与注册表中的 InstallLocation 因末尾反斜杠不一致。
function NormalizeDir(const Dir: String): String;
begin
  Result := RemoveBackslashUnlessRoot(Dir);
end;

{ 判断是否由旧 Tauri 安装器写入的卸载项。旧版 UninstallString 指向 uninstall.bat。 }
function IsLegacyBreezeInstall: Boolean;
var
  UninstallCmd: String;
begin
  Result :=
    RegQueryStringValue(HKCU, LEGACY_UNINSTALL_KEY, 'UninstallString', UninstallCmd)
    and (Pos('uninstall.bat', Lowercase(UninstallCmd)) > 0);
end;

{ 默认安装目录：优先沿用旧版安装位置，否则使用 %LOCALAPPDATA%\breeze。 }
function GetDefaultDir(Param: String): String;
var
  OldDir: String;
begin
  if IsLegacyBreezeInstall
    and RegQueryStringValue(HKCU, LEGACY_UNINSTALL_KEY, 'InstallLocation', OldDir)
    and (OldDir <> '') then
    Result := NormalizeDir(OldDir)
  else
    Result := ExpandConstant('{localappdata}\breeze');
end;

function IsAppRunning: Boolean;
var
  ResultCode: Integer;
begin
  Result :=
    Exec(ExpandConstant('{cmd}'),
      '/c tasklist /FI "IMAGENAME eq zephyr.exe" /NH | find /I "zephyr.exe" >nul',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
    and (ResultCode = 0);
end;

{ 应用启动时会监听命名管道，任意连接都会触发优雅退出。 }
procedure SendShutdownSignal;
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{cmd}'),
    '/c echo. > \\.\pipe\zephyr_shutdown_signal',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure EnsureAppClosed;
var
  I, ResultCode: Integer;
begin
  if not IsAppRunning then
    Exit;

  SendShutdownSignal;

  { 等待优雅退出，最多 15 秒；超时后强制结束。 }
  for I := 1 to 30 do
  begin
    Sleep(500);
    if not IsAppRunning then
      Exit;
  end;

  Exec(ExpandConstant('{sys}\taskkill.exe'), '/IM zephyr.exe /F',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(1000);
end;

{ 旧版安装路径不同时，旧快捷方式会指向已失效的 exe；在 [Icons] 重建前清掉。 }
procedure CleanupLegacyShortcuts;
var
  OldDir, AppDir: String;
begin
  if not IsLegacyBreezeInstall then
    Exit;
  if not RegQueryStringValue(HKCU, LEGACY_UNINSTALL_KEY, 'InstallLocation', OldDir) then
    Exit;

  AppDir := NormalizeDir(ExpandConstant('{app}'));
  if CompareText(NormalizeDir(OldDir), AppDir) = 0 then
    Exit;

  DeleteFile(ExpandConstant('{userdesktop}\Breeze.lnk'));
  DeleteFile(ExpandConstant('{userprograms}\Breeze.lnk'));
end;

{ 新版本安装成功后，移除旧 Tauri 安装器的卸载项与残留文件。
  必须删除旧卸载项：否则旧 uninstall.bat 之后仍可被调用，并会删除整个安装目录。 }
procedure RemoveLegacyRegistration;
var
  OldDir, AppDir, UOld, UApp: String;
begin
  if IsLegacyBreezeInstall then
  begin
    RegQueryStringValue(HKCU, LEGACY_UNINSTALL_KEY, 'InstallLocation', OldDir);
    RegDeleteKeyIncludingSubkeys(HKCU, LEGACY_UNINSTALL_KEY);

    if OldDir <> '' then
    begin
      OldDir := NormalizeDir(OldDir);
      AppDir := NormalizeDir(ExpandConstant('{app}'));
      UOld := Uppercase(AddBackslash(OldDir));
      UApp := Uppercase(AddBackslash(AppDir));
      DeleteFile(AddBackslash(OldDir) + 'uninstall.bat');

      { 仅清理独立的旧目录；避免新旧目录互相嵌套时误删新安装。 }
      if (CompareText(OldDir, AppDir) <> 0)
        and (Pos(UOld, UApp) <> 1)
        and (Pos(UApp, UOld) <> 1) then
        DelTree(OldDir, True, True, True);
    end;
  end;

  DeleteFile(ExpandConstant('{localappdata}\breeze-install-log.json'));
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    EnsureAppClosed;
    CleanupLegacyShortcuts;

    { 整体替换旧 Release，避免残留旧 DLL / 资源；必须在 [Files] 复制前完成。 }
    DelTree(ExpandConstant('{app}\Release'), True, True, True);
    DeleteFile(ExpandConstant('{app}\uninstall.bat'));
  end
  else if CurStep = ssPostInstall then
    RemoveLegacyRegistration;
end;

function InitializeUninstall(): Boolean;
begin
  EnsureAppClosed;
  Result := True;
end;
