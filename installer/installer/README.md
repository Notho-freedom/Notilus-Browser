# Notilus Browser - Installer Scripts

This directory contains scripts for creating installers for different platforms.

## Windows Installer

To create a Windows installer, you'll need [Inno Setup](https://jrsoftware.org/isinfo.php).

### Creating the Windows Installer

1. Install Inno Setup
2. Build the Flutter app: `flutter build windows --release`
3. Run Inno Setup with `notilus_setup.iss`
4. The installer will be created in `installer/Output/`

### Inno Setup Script (notilus_setup.iss)

Create a file `notilus_setup.iss` with the following content:

```inno
[Setup]
AppName=Notilus Browser
AppVersion=1.0.0
DefaultDirName={pf}\Notilus Browser
DefaultGroupName=Notilus Browser
OutputDir=Output
OutputBaseFilename=Notilus-Browser-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Notilus Browser"; Filename: "{app}\notilus.exe"
Name: "{commondesktop}\Notilus Browser"; Filename: "{app}\notilus.exe"

[Run]
Filename: "{app}\notilus.exe"; Description: "Launch Notilus Browser"; Flags: postinstall nowait skipifsilent
```

## Linux Installer

For Linux, create an AppImage or DEB package.

### Creating AppImage

1. Build the Flutter app: `flutter build linux --release`
2. Use `appimagetool` to create the AppImage
3. Script coming soon

### Creating DEB Package

1. Build the Flutter app: `flutter build linux --release`
2. Create a debian package structure
3. Script coming soon

## macOS Installer

For macOS, create a DMG file.

### Creating DMG

1. Build the Flutter app: `flutter build macos --release`
2. Use `create-dmg` tool
3. Script coming soon

## Automated Build

The GitHub Actions workflow in `.github/workflows/build.yml` automatically builds installers for all platforms on every push to main and on tags.

To create a release:

1. Tag your commit: `git tag v1.0.0`
2. Push the tag: `git push origin v1.0.0`
3. GitHub Actions will build and create a release automatically
