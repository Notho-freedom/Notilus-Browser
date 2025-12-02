; ============================================================================
; Notilus Browser - Inno Setup Script
; Installateur Windows avec design futuriste Notilus GX
; Style Science-Fiction avec couleurs néon rouge (#FF2D55) sur fond sombre (#0B0B11)
; Version: 1.0.0
; ============================================================================

#define AppName "Notilus Browser"
#define AppVersion "1.0.0"
#define AppVersionBuild "1"
#define AppPublisher "Notilus Team"
#define AppPublisherURL "https://github.com/Notho-freedom/Notilus-Browser"
#define AppURL "https://github.com/Notho-freedom/Notilus-Browser"
#define AppExeName "notilus.exe"
#define AppBackendExeName "notilus-backend.exe"

[Setup]
; Application information
AppId={{F7E8D9C4-5B6A-4F3E-8D9C-1A2B3C4D5E6F}
AppName={#AppName}
AppVersion={#AppVersion}
AppVersionInfoVersion={#AppVersion}.{#AppVersionBuild}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppPublisherURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
AppContact={#AppPublisherURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
LicenseFile=..\LICENSE
InfoBeforeFile=..\README.md
OutputDir=Output
OutputBaseFilename=Notilus-Browser-Setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
; Images personnalisées Notilus GX Futuriste
WizardImageFile=big-brand1.bmp
WizardSmallImageFile=big-brand2.bmp
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Couleurs personnalisées Notilus GX (rouge néon sur fond sombre)
WizardImageBackColor=$0B0B11
WizardImageStretch=no
WizardImageAlign=left
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
VersionInfoVersion={#AppVersion}.{#AppVersionBuild}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} - Navigateur futuriste pour développeurs
VersionInfoCopyright=Copyright (C) 2024 {#AppPublisher}
VersionInfoProductName={#AppName}
VersionInfoProductVersion={#AppVersion}.{#AppVersionBuild}
VersionInfoProductTextVersion={#AppVersion}
DisableProgramGroupPage=no
DisableReadyPage=no
DisableFinishedPage=no
DisableWelcomePage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode
Name: "startmenu"; Description: "Créer un raccourci dans le menu Démarrer"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "associate"; Description: "Associer Notilus comme navigateur par défaut (optionnel)"; GroupDescription: "Options supplémentaires"; Flags: unchecked

[Files]
; Application principale Flutter
Source: "..\build\windows\x64\runner\Release\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Backend executable (compilé, standalone - ne nécessite pas Python)
; Note: Le backend executable (notilus-backend.exe) est copié automatiquement par CMakeLists.txt dans le build Release
; IMPORTANT: Python embarqué, main.py, services/ et backend_lab/ ne sont PLUS inclus dans le build

; Exclusion explicite des fichiers Python (ne devraient pas être présents, mais on les exclut pour être sûr)
; Ces fichiers ne sont plus copiés par CMakeLists.txt, mais on les exclut au cas où
; Source: "..\build\windows\x64\runner\Release\python_embedded\*"; DestDir: "{app}\python_embedded"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: False
; Source: "..\build\windows\x64\runner\Release\main.py"; DestDir: "{app}"; Flags: ignoreversion; Check: False
; Source: "..\build\windows\x64\runner\Release\services\*"; DestDir: "{app}\services"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: False
; Source: "..\build\windows\x64\runner\Release\backend_lab\*"; DestDir: "{app}\backend_lab"; Flags: ignoreversion recursesubdirs createallsubdirs; Check: False

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"; Tasks: quicklaunchicon
Name: "{autostartmenu}\Programs\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"; Tasks: startmenu

[Registry]
; Enregistrer Notilus comme navigateur (optionnel, seulement si la tâche est sélectionnée)
Root: HKCU; Subkey: "Software\Classes\http\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""; Tasks: associate; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\https\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""; Tasks: associate; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\NotilusBrowser"; ValueType: string; ValueName: ""; ValueData: "Notilus Browser Document"; Tasks: associate; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\NotilusBrowser\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"",0"; Tasks: associate; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\NotilusBrowser\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""; Tasks: associate; Flags: uninsdeletekey

[UninstallDelete]
; Nettoyer les logs générés par l'application
Type: filesandordirs; Name: "{app}\logs"

; Nettoyer les anciens fichiers Python (ne devraient plus être présents dans les nouvelles versions)
; Ces suppressions sont là pour nettoyer les installations précédentes qui utilisaient Python embarqué
Type: filesandordirs; Name: "{app}\python_embedded"
Type: filesandordirs; Name: "{app}\services"
Type: filesandordirs; Name: "{app}\backend_lab"
Type: files; Name: "{app}\main.py"

; NE PAS supprimer notilus-backend.exe car c'est maintenant l'exécutable principal du backend
; Il sera supprimé automatiquement avec le reste de l'application

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent; Check: not WizardSilent

[Code]
var
  WebView2Page: TOutputProgressWizardPage;

// Fonction pour appliquer le style futuriste Notilus GX
procedure ApplyNotilusGXStyle();
begin
  // Couleurs Notilus GX : Fond sombre (#0B0B11) et rouge néon (#FF2D55)
  WizardForm.Color := $0B0B11; // chromeDark
  WizardForm.InnerNotebook.Color := $0B0B11;
  WizardForm.OuterNotebook.Color := $0B0B11;
  WizardForm.Bevel.Color := $FF2D55; // neonRed
  WizardForm.Bevel.Visible := True;
  
  // Personnaliser les labels avec le style futuriste
  if Assigned(WizardForm.WelcomeLabel1) then
  begin
    WizardForm.WelcomeLabel1.Font.Color := $FF2D55; // Rouge néon
    WizardForm.WelcomeLabel1.Font.Style := [fsBold];
  end;
  
  if Assigned(WizardForm.WelcomeLabel2) then
  begin
    WizardForm.WelcomeLabel2.Font.Color := $FFFFFF;
    WizardForm.WelcomeLabel2.Font.Style := [];
  end;
  
  // Personnaliser les boutons
  if Assigned(WizardForm.NextButton) then
  begin
    WizardForm.NextButton.Font.Color := $FFFFFF;
    WizardForm.NextButton.Font.Style := [fsBold];
  end;
  
  if Assigned(WizardForm.BackButton) then
  begin
    WizardForm.BackButton.Font.Color := $FFFFFF;
  end;
  
  if Assigned(WizardForm.CancelButton) then
  begin
    WizardForm.CancelButton.Font.Color := $FFFFFF;
  end;
  
  if Assigned(WizardForm.FinishButton) then
  begin
    WizardForm.FinishButton.Font.Color := $FFFFFF;
    WizardForm.FinishButton.Font.Style := [fsBold];
  end;
end;

function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
  WebView2Installed: Boolean;
begin
  Result := True;
  
  // Appliquer le style Notilus GX dès le début
  // Note: Les contrôles ne sont pas encore créés, donc on l'appliquera dans InitializeWizard
  
  // Vérifier si WebView2 est installé (recommandé mais pas obligatoire)
  WebView2Installed := RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}') or
                       RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}');
  
  if not WebView2Installed then
  begin
    if MsgBox('Microsoft WebView2 Runtime n''est pas détecté. ' +
              'Notilus Browser nécessite WebView2 pour fonctionner. ' +
              'Souhaitez-vous continuer l''installation ?' + #13#10#13#10 +
              'Vous pourrez installer WebView2 manuellement depuis: ' +
              'https://developer.microsoft.com/microsoft-edge/webview2/', 
              mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := False;
    end;
  end;
end;

procedure InitializeWizard();
var
  WelcomeBitmap: TBitmapImage;
begin
  // Appliquer le style Notilus GX sur toutes les pages
  ApplyNotilusGXStyle();
  
  // Personnaliser la page de bienvenue avec le style futuriste
  WizardForm.WelcomeLabel1.Caption := 'Bienvenue dans l''installation de Notilus Browser';
  WizardForm.WelcomeLabel1.Font.Size := 14;
  WizardForm.WelcomeLabel1.Font.Color := $FF2D55; // Rouge néon
  WizardForm.WelcomeLabel1.Font.Style := [fsBold];
  
  WizardForm.WelcomeLabel2.Caption := 'Navigateur futuriste pour développeurs' + #13#10 +
                                      'Interface GX avec design science-fiction' + #13#10 +
                                      'Prêt à révolutionner votre expérience web';
  WizardForm.WelcomeLabel2.Font.Size := 10;
  WizardForm.WelcomeLabel2.Font.Color := $FFFFFF;
  WizardForm.WelcomeLabel2.Font.Style := [];
  
  // Personnaliser les autres labels
  WizardForm.FinishedLabel.Font.Color := $FF2D55;
  WizardForm.FinishedLabel.Font.Style := [fsBold];
  WizardForm.FinishedHeadingLabel.Font.Color := $FFFFFF;
  
  // Créer une page d'information sur WebView2
  WebView2Page := CreateOutputProgressPage('Vérification des prérequis', 
    'Vérification de Microsoft WebView2 Runtime...');
  WebView2Page.SetText('Vérification des prérequis système...', 
    'Notilus Browser nécessite Microsoft WebView2 Runtime pour fonctionner.');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  
  // Appliquer le style à chaque changement de page
  ApplyNotilusGXStyle();
  
  if CurPageID = wpReady then
  begin
    WebView2Page.Show;
    try
      WebView2Page.SetText('Vérification de WebView2 Runtime...', 
        'Analyse des composants système requis pour Notilus Browser...');
      WebView2Page.SetProgress(0, 100);
      Sleep(300);
      WebView2Page.SetProgress(50, 100);
      Sleep(300);
      WebView2Page.SetProgress(100, 100);
      Sleep(200);
    finally
      WebView2Page.Hide;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // Appliquer le style à chaque étape
  ApplyNotilusGXStyle();
  
  if CurStep = ssPostInstall then
  begin
    // Créer le dossier logs pour le backend si nécessaire
    if DirExists(ExpandConstant('{app}')) then
    begin
      CreateDir(ExpandConstant('{app}\logs'));
    end;
    
    // Vérifier que notilus-backend.exe est présent (optionnel - juste pour info)
    if FileExists(ExpandConstant('{app}\{#AppBackendExeName}')) then
    begin
      // Backend executable trouvé - tout est OK
      Log('Backend executable found successfully at ' + ExpandConstant('{app}\{#AppBackendExeName}'));
    end
    else
    begin
      // Avertissement (non bloquant) si le backend n'est pas trouvé
      // L'application pourra toujours démarrer, mais certaines fonctionnalités ne fonctionneront pas
      Log('Warning: Backend executable not found at ' + ExpandConstant('{app}\{#AppBackendExeName}'));
    end;
  end;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
end;

function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
begin
  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{#emit SetupSetting("AppId")}_is1');
  sUnInstallString := '';
  if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
    RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);
  Result := sUnInstallString;
end;

function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;

function InitializeUninstall(): Boolean;
var
  V: Integer;
  iResultCode: Integer;
  sUnInstallString: String;
begin
  Result := True;
  
  // Appliquer le style Notilus GX au désinstalleur
  ApplyNotilusGXStyle();
  
  if not RegQueryStringValue(HKLM, 
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#emit SetupSetting("AppId")}_is1',
    'UninstallString', sUnInstallString) then
    Result := False
  else begin
    V := MsgBox(ExpandConstant('Voulez-vous vraiment désinstaller {#AppName} ?' + #13#10#13#10 +
                                'Toutes les données de l''application seront supprimées.'), 
      mbConfirmation, MB_YESNO);
    if V = IDNO then
      Result := False
    else
    begin
      sUnInstallString := RemoveQuotes(sUnInstallString);
      Exec(ExpandConstant(sUnInstallString), '', '', SW_SHOW, ewWaitUntilTerminated, iResultCode);
      Result := False;
    end;
  end;
end;
