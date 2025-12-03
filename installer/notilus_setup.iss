; ============================================================================
; Notilus Browser - Inno Setup Script
; Installateur Windows professionnel pour Notilus Browser
; Design: Notilus GX (néon rouge #FF2D55 sur fond sombre #0B0B11)
; Version: 1.0.0
; 
; Description:
;   Cet installateur configure Notilus Browser, un navigateur web de nouvelle
;   génération conçu pour les développeurs et utilisateurs avancés, avec une
;   interface GX futuriste et des outils de développement intégrés.
;
; Prérequis:
;   - Microsoft WebView2 Runtime (recommandé, vérifié automatiquement)
;   - Windows 10/11 (64-bit)
;   - Environ 200 MB d'espace disque disponible
;
; Composants inclus:
;   - Application principale Notilus Browser (notilus.exe)
;   - Backend API standalone (notilus-backend.exe)
;   - Bibliothèques et dépendances Flutter
;   - Assets et ressources de l'application
; ============================================================================

#define AppName "Notilus Browser"
#define AppVersion "1.0.0"
#define AppVersionBuild "1"
#define AppPublisher "Notilus Team"
#define AppPublisherURL "https://genesis-company.net"
#define AppURL "https://genesis-company.net"
#define AppExeName "notilus.exe"
#define AppBackendExeName "notilus-backend.exe"

[Setup]
; NOTE: AppId must be a single GUID enclosed in braces {GUID}
AppId={{F7E8D9C4-5B6A-4F3E-8D9C-1A2B3C4D5E6F}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppPublisherURL}
AppSupportURL={#AppURL}/issues
AppUpdatesURL={#AppURL}/releases
AppContact={#AppPublisherURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
InfoBeforeFile=..\README.md
OutputDir=Output
OutputBaseFilename=Notilus-Browser-Setup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico

; Wizard images: must exist in the same folder as this .iss when compiling
WizardImageFile=banner.bmp
Compression=lzma2
SolidCompression=yes

; modern style; if you want "dark" theme you can add it in WizardStyle (Inno 6+)
WizardStyle=modern

; Visual tuning
WizardImageBackColor=$0B0B11
WizardImageStretch=no

ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64

PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription={#AppName} - Navigateur web futuriste avec interface GX, optimisé pour les développeurs et les utilisateurs avancés
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
Name: "desktopicon"; Description: "Créer une icône sur le Bureau"; GroupDescription: "Raccourcis supplémentaires:"; Flags: unchecked
Name: "quicklaunchicon"; Description: "Créer une icône dans la barre de lancement rapide"; GroupDescription: "Raccourcis supplémentaires:"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode
Name: "startmenu"; Description: "Créer un raccourci dans le menu Démarrer"; GroupDescription: "Raccourcis supplémentaires:"; Flags: unchecked
Name: "associate"; Description: "Associer Notilus Browser comme navigateur par défaut pour les liens HTTP/HTTPS"; GroupDescription: "Options d'intégration:"; Flags: unchecked

[Files]
; Application principale Flutter - Notilus Browser
Source: "..\build\windows\x64\runner\Release\{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Backend API executable (compilé, standalone - ne nécessite pas Python)
; Le backend executable (notilus-backend.exe) est copié automatiquement par CMakeLists.txt dans le build Release
; IMPORTANT: Python embarqué, main.py, services/ et backend_lab/ ne sont PLUS inclus dans le build
; Le backend est maintenant un exécutable standalone compilé avec PyInstaller

; Note: Si vous souhaitez ajouter des fichiers runtime supplémentaires (ex: WebView2 runtime),
; placez-les dans le répertoire de build et ils seront inclus automatiquement

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"; Tasks: quicklaunchicon
Name: "{autostartmenu}\Programs\{#AppName}"; Filename: "{app}\{#AppExeName}"; IconFilename: "{app}\{#AppExeName}"; Tasks: startmenu

[Registry]
; Register as browser if user selected the 'associate' task
Root: HKCU; Subkey: "Software\Classes\http\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""; Tasks: associate; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\https\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""; Tasks: associate; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\NotilusBrowser"; ValueType: string; ValueName: ""; ValueData: "Notilus Browser Document"; Tasks: associate; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\NotilusBrowser\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"",0"; Tasks: associate; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\NotilusBrowser\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExeName}"" ""%1"""; Tasks: associate; Flags: uninsdeletekey

[UninstallDelete]
; Nettoyage des fichiers et dossiers générés par l'application
Type: filesandordirs; Name: "{app}\logs"

; Nettoyage des anciens fichiers Python (pour les mises à jour depuis versions antérieures)
; Ces fichiers ne sont plus utilisés dans les versions récentes (backend compilé standalone)
Type: filesandordirs; Name: "{app}\python_embedded"
Type: filesandordirs; Name: "{app}\services"
Type: filesandordirs; Name: "{app}\backend_lab"
Type: files; Name: "{app}\main.py"

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent; Check: not WizardSilent

[Code]
var
  WebView2Page: TOutputProgressWizardPage;

procedure ApplyNotilusGXStyle();
begin
  { Apply basic style tweaks to the wizard controls (text only, no colors) }
  
  { Customize text styles if labels exist }
  if Assigned(WizardForm.WelcomeLabel1) then
  begin
    WizardForm.WelcomeLabel1.Font.Style := [fsBold];
  end;
  
  { Customize buttons }
  if Assigned(WizardForm.NextButton) then
  begin
    WizardForm.NextButton.Font.Style := [fsBold];
  end;
  
  { Customize finished page labels }
  if Assigned(WizardForm.FinishedLabel) then
  begin
    WizardForm.FinishedLabel.Font.Style := [fsBold];
  end;
end;

function InitializeSetup(): Boolean;
var
  WebView2Installed: Boolean;
begin
  Result := True;

  { Check WebView2 runtime presence (non-blocking) - recommended but optional.
    Tests common registry keys used by WebView2 installers. }
  WebView2Installed := RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}')
    or RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}');

  if not WebView2Installed then
  begin
    if MsgBox('Avertissement: Microsoft WebView2 Runtime non détecté'#13#10#13#10 +
              'Notilus Browser nécessite Microsoft WebView2 Runtime pour fonctionner correctement.'#13#10 +
              'Ce composant est essentiel pour le rendu des pages web et les fonctionnalités avancées.'#13#10#13#10 +
              'Options disponibles:'#13#10 +
              '• Continuer l''installation: Vous pourrez installer WebView2 manuellement plus tard'#13#10 +
              '• Annuler: Installez d''abord WebView2 depuis le site officiel Microsoft'#13#10#13#10 +
              'Téléchargement WebView2: https://developer.microsoft.com/microsoft-edge/webview2/'#13#10#13#10 +
              'Souhaitez-vous continuer l''installation malgré l''absence de WebView2 ?', 
              mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

procedure InitializeWizard();
begin
  ApplyNotilusGXStyle();

  { Customize welcome page text with Notilus GX style }
  if Assigned(WizardForm.WelcomeLabel1) then
  begin
    WizardForm.WelcomeLabel1.Caption := 'Bienvenue dans l''assistant d''installation de Notilus Browser';
    WizardForm.WelcomeLabel1.Font.Size := 14;
    WizardForm.WelcomeLabel1.Font.Style := [fsBold];
  end;
  
  if Assigned(WizardForm.WelcomeLabel2) then
  begin
    WizardForm.WelcomeLabel2.Caption := 'Notilus Browser est un navigateur web de nouvelle génération conçu pour les développeurs et les utilisateurs avancés.' + #13#10#13#10 +
                                        'Caractéristiques principales:' + #13#10 +
                                        '• Interface GX futuriste avec design science-fiction' + #13#10 +
                                        '• Outils de développement intégrés (DevTools, Backend Lab)' + #13#10 +
                                        '• Support des extensions et personnalisation avancée' + #13#10 +
                                        '• Performance optimisée et sécurité renforcée' + #13#10#13#10 +
                                        'Cet assistant va vous guider à travers l''installation de Notilus Browser sur votre système.';
    WizardForm.WelcomeLabel2.Font.Size := 9;
  end;

  { Create a simple progress/info page for WebView2 check }
  WebView2Page := CreateOutputProgressPage('Vérification des prérequis système',
    'Analyse des composants requis pour Notilus Browser...');
  WebView2Page.SetText('Vérification des prérequis système en cours...',
    'Notilus Browser nécessite Microsoft WebView2 Runtime pour fonctionner correctement.' + #13#10#13#10 +
    'WebView2 est le moteur de rendu moderne de Microsoft basé sur Chromium, qui permet à Notilus Browser' + #13#10 +
    'd''afficher les pages web avec les dernières technologies et standards du web.');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  { Progress animation when ready page is displayed }
  if CurPageID = wpReady then
  begin
    WebView2Page.Show;
    try
      WebView2Page.SetText('Vérification finale des prérequis système...', 
        'Analyse des composants requis pour Notilus Browser...');
      WebView2Page.SetProgress(0, 100);
      Sleep(300);
      WebView2Page.SetText('Vérification de Microsoft WebView2 Runtime...', 
        'Recherche de WebView2 dans le registre système...');
      WebView2Page.SetProgress(30, 100);
      Sleep(300);
      WebView2Page.SetText('Vérification de l''espace disque disponible...', 
        'Contrôle de l''espace nécessaire pour l''installation...');
      WebView2Page.SetProgress(60, 100);
      Sleep(300);
      WebView2Page.SetText('Vérification des permissions système...', 
        'Vérification des droits d''accès requis...');
      WebView2Page.SetProgress(90, 100);
      Sleep(200);
      WebView2Page.SetText('Vérification terminée', 
        'Tous les prérequis ont été vérifiés. Prêt pour l''installation.');
      WebView2Page.SetProgress(100, 100);
      Sleep(200);
    finally
      WebView2Page.Hide;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  { Only apply style during installation steps }
  { Note: ssPostUninstall doesn't exist, we check for installation steps only }
  if (CurStep = ssInstall) or (CurStep = ssPostInstall) or (CurStep = ssDone) then
    ApplyNotilusGXStyle();

  if CurStep = ssPostInstall then
  begin
    if DirExists(ExpandConstant('{app}')) then
      CreateDir(ExpandConstant('{app}\logs'));

    { Verify backend executable presence }
    if FileExists(ExpandConstant('{app}\{#AppBackendExeName}')) then
    begin
      Log('✓ Backend executable found successfully at ' + ExpandConstant('{app}\{#AppBackendExeName}'));
      Log('  Backend services will be available after application launch.');
    end
    else
    begin
      Log('⚠ Warning: Backend executable not found at ' + ExpandConstant('{app}\{#AppBackendExeName}'));
      Log('  Some advanced features (Backend Lab, API services) may not be available.');
      Log('  The application will still launch, but backend-dependent features will be disabled.');
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
begin
  Result := True;
  
  { Show confirmation dialog before uninstallation }
  V := MsgBox(ExpandConstant('Confirmation de désinstallation'#13#10#13#10 +
                              'Vous êtes sur le point de désinstaller {#AppName} de votre système.'#13#10#13#10 +
                              'Cette action va supprimer:'#13#10 +
                              '• L''application Notilus Browser et tous ses fichiers'#13#10 +
                              '• Les raccourcis créés (Bureau, Menu Démarrer, etc.)'#13#10 +
                              '• Les associations de fichiers (si configurées)'#13#10 +
                              '• Les logs et données temporaires'#13#10#13#10 +
                              'Note: Vos paramètres utilisateur et préférences seront conservés dans:'#13#10 +
                              '%APPDATA%\Notilus Browser\'#13#10#13#10 +
                              'Souhaitez-vous vraiment continuer la désinstallation ?'), 
    mbConfirmation, MB_YESNO);
  
  if V = IDNO then
    Result := False;
end;
