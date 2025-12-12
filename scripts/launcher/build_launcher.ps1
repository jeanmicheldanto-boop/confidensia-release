# Script de Compilation du Launcher ConfidensIA
# Compile les versions DEBUG (avec console) et PRODUCTION (sans console)

param(
    [string]$Version = "1.0.1",
    [switch]$DebugOnly,
    [switch]$ProductionOnly,
    [switch]$SkipUpload
)

$ErrorActionPreference = "Stop"

# Chemins
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$VenvPython = Join-Path $RootDir "temp_venv_packaging\Scripts\python.exe"
$VenvPyInstaller = Join-Path $RootDir "temp_venv_packaging\Scripts\pyinstaller.exe"
$IconPath = Join-Path $RootDir "pseudo_UI\public\icone_cia_transp.ico"
$DistDir = Join-Path $ScriptDir "dist"

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  Compilation Launcher ConfidensIA" -ForegroundColor Cyan
Write-Host "  Version: $Version" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Vérifications préalables
Write-Host "[1/5] Vérifications préalables..." -ForegroundColor Yellow

if (-not (Test-Path $VenvPython)) {
    Write-Host "ERREUR: Python introuvable dans temp_venv_packaging" -ForegroundColor Red
    Write-Host "Chemin attendu: $VenvPython" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $VenvPyInstaller)) {
    Write-Host "ERREUR: PyInstaller introuvable" -ForegroundColor Red
    Write-Host "Installation de PyInstaller..." -ForegroundColor Yellow
    & $VenvPython -m pip install pyinstaller
}

if (-not (Test-Path $IconPath)) {
    Write-Host "AVERTISSEMENT: Icône introuvable à $IconPath" -ForegroundColor Yellow
    $IconPath = ""
}

# Vérification des packages critiques
Write-Host "Vérification des dépendances critiques..." -ForegroundColor Gray
$PipList = & "$RootDir\temp_venv_packaging\Scripts\pip.exe" list
$HasRequests = $PipList | Select-String -Pattern "requests"
$HasPillow = $PipList | Select-String -Pattern "Pillow"

if (-not $HasRequests) {
    Write-Host "ERREUR: Package 'requests' manquant dans temp_venv_packaging" -ForegroundColor Red
    exit 1
}

if (-not $HasPillow) {
    Write-Host "ERREUR: Package 'Pillow' manquant dans temp_venv_packaging" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Environnement valide" -ForegroundColor Green

# Vérification des fichiers requis
Write-Host "`n[2/5] Vérification des fichiers requis..." -ForegroundColor Yellow

$RequiredFiles = @(
    "launcher.py",
    "download_manifest.json",
    "logo.png"
)

foreach ($File in $RequiredFiles) {
    $FilePath = Join-Path $ScriptDir $File
    if (-not (Test-Path $FilePath)) {
        Write-Host "ERREUR: Fichier manquant: $File" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ $File" -ForegroundColor Green
}

# Flags PyInstaller communs
$CommonFlags = @(
    "--clean",
    "--onefile",
    "--add-data=download_manifest.json;.",
    "--add-data=logo.png;.",
    "--hidden-import=PIL._tkinter_finder",
    "--collect-all", "requests",
    "--collect-all", "PIL",
    "--collect-all", "urllib3",
    "--collect-all", "certifi",
    "--collect-all", "setuptools"
)

if ($IconPath) {
    $CommonFlags += "--icon=$IconPath"
}

# Fonction de compilation
function Compile-Launcher {
    param(
        [string]$Name,
        [string]$Mode,
        [string[]]$ExtraFlags
    )
    
    Write-Host "`nCompilation $Name..." -ForegroundColor Cyan
    
    $AllFlags = @("--name=$Name", "--$Mode") + $CommonFlags + $ExtraFlags + "launcher.py"
    
    $StartTime = Get-Date
    & $VenvPyInstaller $AllFlags
    $Duration = (Get-Date) - $StartTime
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERREUR: Échec de la compilation $Name" -ForegroundColor Red
        exit 1
    }
    
    $ExePath = Join-Path $DistDir "$Name.exe"
    if (-not (Test-Path $ExePath)) {
        Write-Host "ERREUR: Exécutable non créé: $ExePath" -ForegroundColor Red
        exit 1
    }
    
    $SizeMB = [math]::Round((Get-Item $ExePath).Length / 1MB, 2)
    
    Write-Host "✓ $Name.exe créé avec succès" -ForegroundColor Green
    Write-Host "  Taille: $SizeMB MB" -ForegroundColor Gray
    Write-Host "  Durée: $([math]::Round($Duration.TotalSeconds, 1))s" -ForegroundColor Gray
    
    if ($SizeMB -lt 20) {
        Write-Host "AVERTISSEMENT: Taille suspecte (< 20 MB), dépendances manquantes?" -ForegroundColor Yellow
    }
    
    return $ExePath
}

# Compilation version DEBUG
$DebugExe = $null
if (-not $ProductionOnly) {
    Write-Host "`n[3/5] Compilation version DEBUG (avec console)..." -ForegroundColor Yellow
    $DebugExe = Compile-Launcher -Name "ConfidensIA_DEBUG" -Mode "console"
}

# Compilation version PRODUCTION
$ProdExe = $null
if (-not $DebugOnly) {
    Write-Host "`n[4/5] Compilation version PRODUCTION (sans console)..." -ForegroundColor Yellow
    $ProdExe = Compile-Launcher -Name "ConfidensIA" -Mode "windowed"
}

# Résumé
Write-Host "`n[5/5] Résumé de la compilation" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Cyan

if ($DebugExe) {
    $DebugSize = [math]::Round((Get-Item $DebugExe).Length / 1MB, 2)
    Write-Host "✓ DEBUG:      $DebugSize MB" -ForegroundColor Green
    Write-Host "  Chemin: $DebugExe" -ForegroundColor Gray
}

if ($ProdExe) {
    $ProdSize = [math]::Round((Get-Item $ProdExe).Length / 1MB, 2)
    Write-Host "✓ PRODUCTION: $ProdSize MB" -ForegroundColor Green
    Write-Host "  Chemin: $ProdExe" -ForegroundColor Gray
}

# Upload sur GitHub (optionnel)
if (-not $SkipUpload) {
    Write-Host "`n[OPTIONNEL] Upload sur GitHub Release v$Version" -ForegroundColor Yellow
    Write-Host "Voulez-vous uploader sur GitHub? (O/N): " -NoNewline -ForegroundColor Cyan
    $Response = Read-Host
    
    if ($Response -eq "O" -or $Response -eq "o") {
        # Recherche du repo
        $RepoPath = $null
        $PossiblePaths = @(
            (Join-Path $RootDir "pseudo_API"),
            (Join-Path $RootDir "pseudo_UI"),
            (Join-Path $RootDir "laplume")
        )
        
        foreach ($Path in $PossiblePaths) {
            if (Test-Path (Join-Path $Path ".git")) {
                $RepoPath = $Path
                break
            }
        }
        
        if (-not $RepoPath) {
            Write-Host "ERREUR: Aucun repo git trouvé" -ForegroundColor Red
        } else {
            Push-Location $RepoPath
            
            if ($DebugExe) {
                Write-Host "Upload ConfidensIA_DEBUG.exe..." -ForegroundColor Gray
                gh release upload "v$Version" $DebugExe --clobber --repo jeanmicheldanto-boop/confidensia-release
            }
            
            if ($ProdExe) {
                Write-Host "Upload ConfidensIA.exe..." -ForegroundColor Gray
                gh release upload "v$Version" $ProdExe --clobber --repo jeanmicheldanto-boop/confidensia-release
            }
            
            Write-Host "✓ Upload terminé" -ForegroundColor Green
            
            Pop-Location
        }
    }
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  Compilation terminée avec succès!" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Cyan
