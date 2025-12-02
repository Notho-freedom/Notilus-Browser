# Script PowerShell pour créer la première release de Notilus
# Automatise tout le processus : build backend + intégration + build Flutter

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Release Notilus v1.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $rootDir "backend"
$flutterBuildDir = Join-Path $rootDir "build\windows\x64\runner\Release"

# Étape 1: Vérifier les prérequis
Write-Host "[1/4] Vérification des prérequis..." -ForegroundColor Yellow

# Vérifier Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "  Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "  [ERREUR] Python n'est pas installé" -ForegroundColor Red
    exit 1
}

# Vérifier Flutter
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "  Flutter: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "  [ERREUR] Flutter n'est pas installé" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Étape 2: Vérifier le backend compilé
Write-Host "[2/3] Vérification du backend compilé..." -ForegroundColor Yellow
Set-Location $backendDir

# Chercher notilus-backend.exe (avec tiret, nom actuel)
$backendExe = Join-Path $backendDir "dist\notilus-backend.exe"
# Fallback sur l'ancien nom si nécessaire
if (-not (Test-Path $backendExe)) {
    $backendExe = Join-Path $backendDir "dist\notilus_backend.exe"
}
if (-not (Test-Path $backendExe)) {
    Write-Host "  [ERREUR] Le backend compilé (notilus-backend.exe) n'existe pas dans backend/dist/" -ForegroundColor Red
    Write-Host "  Veuillez compiler le backend avec PyInstaller ou votre outil de build" -ForegroundColor Yellow
    exit 1
}

$sizeMB = (Get-Item $backendExe).Length / 1MB
Write-Host "  ✅ Backend compilé trouvé: $([math]::Round($sizeMB, 2)) MB" -ForegroundColor Green
Write-Host ""

# Étape 3: Build Flutter Release
Write-Host "[3/3] Build Flutter Release..." -ForegroundColor Yellow
Set-Location $rootDir

Write-Host "  Nettoyage du build précédent..." -ForegroundColor Gray
flutter clean

Write-Host "  Récupération des dépendances..." -ForegroundColor Gray
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERREUR] Échec de la récupération des dépendances" -ForegroundColor Red
    exit 1
}

Write-Host "  Build Windows Release..." -ForegroundColor Gray
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERREUR] Échec du build Flutter" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Vérification finale
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ Release créée avec succès!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📂 Fichiers de release:" -ForegroundColor Yellow
Write-Host "  Emplacement: $flutterBuildDir" -ForegroundColor White
Write-Host ""

# Lister les fichiers principaux
if (Test-Path $flutterBuildDir) {
    Write-Host "  Fichiers principaux:" -ForegroundColor Gray
    $exeFiles = Get-ChildItem -Path $flutterBuildDir -Filter "*.exe" -ErrorAction SilentlyContinue
    foreach ($file in $exeFiles) {
        $sizeMB = $file.Length / 1MB
        Write-Host "    - $($file.Name) ($([math]::Round($sizeMB, 2)) MB)" -ForegroundColor White
    }
    
    # Vérifier le fichier backend
    Write-Host ""
    Write-Host "  Fichier backend:" -ForegroundColor Gray
    if (Test-Path (Join-Path $flutterBuildDir "notilus-backend.exe")) {
        $backendSize = (Get-Item (Join-Path $flutterBuildDir "notilus-backend.exe")).Length / 1MB
        Write-Host "    ✅ notilus-backend.exe ($([math]::Round($backendSize, 2)) MB)" -ForegroundColor Green
    } else {
        Write-Host "    ❌ notilus-backend.exe (manquant)" -ForegroundColor Red
        Write-Host "    [INFO] Le backend sera copié manuellement ou via l'installateur" -ForegroundColor Yellow
    }
    
    # Vérifier qu'il n'y a PAS de Python embarqué (ne devrait plus être là)
    if (Test-Path (Join-Path $flutterBuildDir "python_embedded")) {
        Write-Host "    ⚠️  python_embedded/ (ne devrait plus être présent!)" -ForegroundColor Yellow
    } else {
        Write-Host "    ✅ python_embedded/ (correctement absent)" -ForegroundColor Green
    }
    
    if (Test-Path (Join-Path $flutterBuildDir "main.py")) {
        Write-Host "    ⚠️  main.py (ne devrait plus être présent!)" -ForegroundColor Yellow
    } else {
        Write-Host "    ✅ main.py (correctement absent)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "🎉 La release est prête!" -ForegroundColor Green
Write-Host ""
Write-Host "Pour tester:" -ForegroundColor Yellow
Write-Host "  cd $flutterBuildDir" -ForegroundColor White
Write-Host "  .\notilus.exe" -ForegroundColor White
Write-Host ""

