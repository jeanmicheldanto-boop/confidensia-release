# Script de packaging pour ConfensIA
# Cree les archives ZIP qui seront hebergees sur le CDN

param(
    [string]$OutputDir = ".\dist\cdn",
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ConfensIA - Packaging v$Version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Creer le dossier de sortie
$OutputPath = New-Item -ItemType Directory -Force -Path $OutputDir
Write-Host "OK Dossier de sortie: $OutputPath" -ForegroundColor Green

# ============================================================================
# 1. FRONTEND STATIQUE
# ============================================================================
Write-Host "`n[1/6] Packaging du frontend Next.js..." -ForegroundColor Yellow

$FrontendSource = "..\pseudo_UI\out"
$FrontendZip = Join-Path $OutputPath "pseudo_UI-out-v$Version.zip"

if (Test-Path $FrontendSource) {
    # Créer la structure runtime/pseudo_UI/out/
    $TempFrontend = New-Item -ItemType Directory -Force -Path "$OutputPath\temp_frontend\runtime\pseudo_UI\out"
    Copy-Item -Path "$FrontendSource\*" -Destination $TempFrontend -Recurse -Force
    
    Compress-Archive -Path "$OutputPath\temp_frontend\*" -DestinationPath $FrontendZip -Force
    $size = [math]::Round((Get-Item $FrontendZip).Length / 1MB, 2)
    Write-Host "  OK Frontend: $size MB" -ForegroundColor Green
    
    # Nettoyer
    Remove-Item -Path "$OutputPath\temp_frontend" -Recurse -Force
} else {
    Write-Host "  WARN Frontend non trouve" -ForegroundColor Red
}

# ============================================================================
# 2. BACKEND API
# ============================================================================
Write-Host "`n[2/6] Packaging du backend FastAPI..." -ForegroundColor Yellow

$BackendSource = "..\pseudo_API"
$BackendZip = Join-Path $OutputPath "pseudo_API-src-v$Version.zip"

# Créer la structure runtime/pseudo_API/
$TempBackend = New-Item -ItemType Directory -Force -Path "$OutputPath\temp_backend\runtime\pseudo_API"

# Copier les fichiers nécessaires
Copy-Item -Path "$BackendSource\*.py" -Destination $TempBackend -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$BackendSource\requirements.txt" -Destination $TempBackend -Force -ErrorAction SilentlyContinue
if (Test-Path "$BackendSource\middleware") {
    Copy-Item -Path "$BackendSource\middleware" -Destination "$TempBackend\middleware" -Recurse -Force
}
if (Test-Path "$BackendSource\services") {
    Copy-Item -Path "$BackendSource\services" -Destination "$TempBackend\services" -Recurse -Force
}

# ⚠️ CRITIQUE : Copier .env.production vers .env pour distribution
# Ce fichier contient UNIQUEMENT les clés publiques (ANON_KEY, pas SERVICE_KEY)
if (Test-Path "$BackendSource\.env.production") {
    Copy-Item -Path "$BackendSource\.env.production" -Destination "$TempBackend\.env" -Force
    Write-Host "  OK .env.production copie vers .env" -ForegroundColor Green
} else {
    Write-Host "  WARN .env.production non trouve - le backend ne pourra pas demarrer!" -ForegroundColor Red
}

# Créer l'archive
Compress-Archive -Path "$OutputPath\temp_backend\*" -DestinationPath $BackendZip -Force
$size = [math]::Round((Get-Item $BackendZip).Length / 1MB, 2)
Write-Host "  OK Backend: $size MB" -ForegroundColor Green

# Nettoyer
Remove-Item -Path "$OutputPath\temp_backend" -Recurse -Force

# ============================================================================
# 3. CODE SOURCE LAPLUME
# ============================================================================
Write-Host "`n[3/6] Packaging de LaPlume..." -ForegroundColor Yellow

$LaplumeSource = "..\laplume"
$LaplumeZip = Join-Path $OutputPath "laplume-src-v$Version.zip"

# Créer la structure runtime/laplume/
$TempLaplume = New-Item -ItemType Directory -Force -Path "$OutputPath\temp_laplume\runtime\laplume"

# Copier les dossiers essentiels
Copy-Item -Path "$LaplumeSource\app_core" -Destination "$TempLaplume\app_core" -Recurse -Force
Copy-Item -Path "$LaplumeSource\cli" -Destination "$TempLaplume\cli" -Recurse -Force
Copy-Item -Path "$LaplumeSource\config" -Destination "$TempLaplume\config" -Recurse -Force
Copy-Item -Path "$LaplumeSource\gazetteer" -Destination "$TempLaplume\gazetteer" -Recurse -Force
Copy-Item -Path "$LaplumeSource\rules" -Destination "$TempLaplume\rules" -Recurse -Force
Copy-Item -Path "$LaplumeSource\*.py" -Destination $TempLaplume -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$LaplumeSource\requirements.txt" -Destination $TempLaplume -Force

# Créer l'archive
Compress-Archive -Path "$OutputPath\temp_laplume\*" -DestinationPath $LaplumeZip -Force
$size = [math]::Round((Get-Item $LaplumeZip).Length / 1MB, 2)
Write-Host "  OK LaPlume: $size MB" -ForegroundColor Green

# Nettoyer
Remove-Item -Path "$OutputPath\temp_laplume" -Recurse -Force

# ============================================================================
# 4. PYTHON EMBEDDED
# ============================================================================
Write-Host "`n[4/6] Packaging Python Embedded..." -ForegroundColor Yellow

$PythonUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
$PythonZip = Join-Path $OutputPath "python-3.11.9-embed-amd64.zip"

if (-not (Test-Path $PythonZip)) {
    Write-Host "  Telechargement de Python 3.11.9 embedded..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $PythonUrl -OutFile $PythonZip
}

$size = [math]::Round((Get-Item $PythonZip).Length / 1MB, 2)
Write-Host "  OK Python Embedded: $size MB" -ForegroundColor Green

# ============================================================================
# 5. MODELE NER (si disponible localement)
# ============================================================================
Write-Host "`n[5/6] Packaging du modele NER..." -ForegroundColor Yellow

$ModelSource = "..\laplume\models\titibongbong-fp16"
$ModelZip = Join-Path $OutputPath "titibongbong-fp16-v$Version.zip"

if (Test-Path $ModelSource) {
    # Créer la structure runtime/models/titibongbong-fp16/
    $TempModel = New-Item -ItemType Directory -Force -Path "$OutputPath\temp_model\runtime\models\titibongbong-fp16"
    Copy-Item -Path "$ModelSource\*" -Destination $TempModel -Recurse -Force
    
    Compress-Archive -Path "$OutputPath\temp_model\*" -DestinationPath $ModelZip -Force
    $size = [math]::Round((Get-Item $ModelZip).Length / 1MB, 2)
    Write-Host "  OK Modele NER: $size MB" -ForegroundColor Green
    
    # Nettoyer
    Remove-Item -Path "$OutputPath\temp_model" -Recurse -Force
} else {
    Write-Host "  WARN Modele non trouve localement" -ForegroundColor Yellow
}

# ============================================================================
# 6. DEPENDANCES PYTHON
# ============================================================================
Write-Host "`n[6/6] Info: Bundle de dependances..." -ForegroundColor Yellow
Write-Host "  WARN Cette etape necessite un environnement virtuel configure" -ForegroundColor Yellow
Write-Host "  Voir documentation pour creer dependencies-bundle.zip" -ForegroundColor Cyan

# ============================================================================
# RESUME
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Packaging termine!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Get-ChildItem $OutputPath -Filter "*.zip" | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  Archive $($_.Name): $size MB" -ForegroundColor White
}

$totalSize = [math]::Round((Get-ChildItem $OutputPath -Filter "*.zip" | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
Write-Host "`n  Total: $totalSize MB" -ForegroundColor Cyan
Write-Host ""
Write-Host "Les archives sont pretes a etre uploadees sur votre CDN." -ForegroundColor Green
Write-Host "Pensez a mettre a jour download_manifest.json avec les URLs finales." -ForegroundColor Yellow
