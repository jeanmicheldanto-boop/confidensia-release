# Guide de Compilation du Launcher ConfidensIA

**Date:** 12 décembre 2025  
**Version:** 1.0.1  
**Objectif:** Créer un exécutable Windows standalone qui télécharge et installe automatiquement ConfidensIA

---

## 🎯 Vue d'Ensemble

Le launcher est un exécutable PyInstaller **onefile** qui :
1. Affiche un splash screen avec logo (tkinter)
2. Télécharge les composants depuis GitHub Release
3. Extrait et installe Python embedded + dépendances
4. Lance le serveur FastAPI local
5. Ouvre le navigateur automatiquement

**Taille finale:** 26.61 MB  
**Dépendances embarquées:** requests, Pillow, tkinter, urllib3, certifi, setuptools

---

## ⚠️ Prérequis CRITIQUES

### 1. Environnement Python de Compilation

**NE PAS compiler avec Python système !** Le launcher doit être compilé avec un environnement Python qui contient **toutes** les dépendances nécessaires.

**Environnement requis:** `temp_venv_packaging` créé lors du packaging CDN

```powershell
# Vérification de l'environnement
C:\Users\Lenovo\Confens-IA\temp_venv_packaging\Scripts\python.exe --version
# Doit afficher: Python 3.11.9 ou 3.13.7

# Vérification des packages critiques
C:\Users\Lenovo\Confens-IA\temp_venv_packaging\Scripts\pip.exe list | Select-String -Pattern "requests|Pillow|pyinstaller"
# Doit montrer:
# - requests 2.32.5
# - Pillow 12.0.0
# - pyinstaller 6.17.0
```

### 2. Fichiers Requis

Dans `scripts/launcher/` :
- ✅ `launcher.py` (961 lignes, code principal)
- ✅ `download_manifest.json` (manifeste embarqué avec URLs et SHA256)
- ✅ `logo.png` (logo pour splash screen)
- ✅ `../../pseudo_UI/public/icone_cia_transp.ico` (icône Windows)

---

## 🔧 Commande de Compilation

### Version DEBUG (avec console visible)

Pour le développement et débogage sur PC tiers :

```powershell
cd C:\Users\Lenovo\Confens-IA\scripts\launcher

..\..\temp_venv_packaging\Scripts\pyinstaller.exe `
    --clean `
    --name="ConfidensIA_DEBUG" `
    --onefile `
    --console `
    --icon="..\..\pseudo_UI\public\icone_cia_transp.ico" `
    --add-data="download_manifest.json;." `
    --add-data="logo.png;." `
    --hidden-import="PIL._tkinter_finder" `
    --collect-all requests `
    --collect-all PIL `
    --collect-all urllib3 `
    --collect-all certifi `
    --collect-all setuptools `
    launcher.py
```

**Résultat:** `dist\ConfidensIA_DEBUG.exe` (26.61 MB)

### Version PRODUCTION (sans console)

Pour distribution aux utilisateurs finaux :

```powershell
cd C:\Users\Lenovo\Confens-IA\scripts\launcher

..\..\temp_venv_packaging\Scripts\pyinstaller.exe `
    --clean `
    --name="ConfidensIA" `
    --onefile `
    --windowed `
    --icon="..\..\pseudo_UI\public\icone_cia_transp.ico" `
    --add-data="download_manifest.json;." `
    --add-data="logo.png;." `
    --hidden-import="PIL._tkinter_finder" `
    --collect-all requests `
    --collect-all PIL `
    --collect-all urllib3 `
    --collect-all certifi `
    --collect-all setuptools `
    launcher.py
```

**Résultat:** `dist\ConfidensIA.exe` (26.61 MB)

---

## 📊 Explication des Flags PyInstaller

### Flags de Base

| Flag | Description | Raison |
|------|-------------|--------|
| `--clean` | Supprime cache PyInstaller | Force rebuild complet, évite cache corrompu |
| `--name="ConfidensIA"` | Nom de l'exécutable | Produit ConfidensIA.exe |
| `--onefile` | Archive unique | Un seul .exe (vs dossier avec DLLs) |
| `--windowed` ou `--console` | Type d'interface | --windowed = pas de console (prod), --console = logs visibles (debug) |
| `--icon="..."` | Icône Windows | Icône visible dans explorateur et barre des tâches |

### Flags de Données

| Flag | Description | Raison |
|------|-------------|--------|
| `--add-data="download_manifest.json;."` | Embarque manifeste | Contient URLs + SHA256 des fichiers v1.0.1 |
| `--add-data="logo.png;."` | Embarque logo | Image du splash screen |

### Flags d'Imports Cachés

| Flag | Description | Raison |
|------|-------------|--------|
| `--hidden-import="PIL._tkinter_finder"` | Module PIL pour tkinter | Affichage images dans GUI tkinter |
| `--collect-all requests` | **CRITIQUE** | Téléchargement fichiers depuis GitHub |
| `--collect-all PIL` | **CRITIQUE** | Affichage logo splash screen |
| `--collect-all urllib3` | Dépendance de requests | HTTP connection pooling |
| `--collect-all certifi` | Dépendance de requests | Certificats SSL |
| `--collect-all setuptools` | Utilitaires Python | Gestion packages et métadata |

---

## 🐛 Problèmes Résolus

### Problème 1: "No module named 'requests'"

**Symptôme:** Launcher crashe au démarrage avec `ModuleNotFoundError: No module named 'requests'`

**Cause:** PyInstaller ne détecte pas automatiquement requests car il est importé dans un thread

**Solution:** Ajout de `--collect-all requests --collect-all urllib3 --collect-all certifi`

### Problème 2: Taille du Launcher Trop Petite

**Symptôme:** Launcher compilé fait 16-19 MB au lieu de 30+ MB attendu

**Cause:** Compilation avec environnement Python incomplet (ex: `.venv` minimal)

**Solution:** **Toujours** compiler avec `temp_venv_packaging` qui contient toutes les dépendances

### Problème 3: Splash Screen ne s'Affiche Pas

**Symptôme:** Fenêtre blanche ou crash au lancement

**Cause:** PIL (Pillow) ou tkinter non embarqué

**Solution:** Ajout de `--collect-all PIL --hidden-import="PIL._tkinter_finder"`

### Problème 4: Warnings "No module named 'js'"

**Symptôme:** Warning pendant compilation: `Failed to collect submodules for 'urllib3.contrib.emscripten'`

**Impact:** **AUCUN** - urllib3.contrib.emscripten est pour Python WebAssembly (navigateur), pas Windows

**Action:** Ignorer ce warning

---

## ✅ Validation Post-Compilation

### 1. Vérification Taille

```powershell
Get-Item dist\ConfidensIA.exe | Select-Object Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB,2)}}
```

**Attendu:** 26-27 MB  
**Si < 20 MB:** Compilation incorrecte, manque des dépendances

### 2. Test Local (Version DEBUG)

```powershell
cd C:\Users\Lenovo\Confens-IA\scripts\launcher\dist
.\ConfidensIA_DEBUG.exe
```

**Vérifications:**
- ✅ Console PowerShell apparaît avec logs
- ✅ Fenêtre splash screen s'affiche avec logo
- ✅ Logs montrent: `[DEBUG] Téléchargement de https://github.com/...`
- ✅ Pas d'erreur `ModuleNotFoundError`

### 3. Test Minimal (Version PRODUCTION)

```powershell
cd C:\Users\Lenovo\Confens-IA\scripts\launcher\dist
Start-Process .\ConfidensIA.exe
```

**Vérifications:**
- ✅ Splash screen apparaît (pas de console)
- ✅ Processus `ConfidensIA` visible dans Gestionnaire des tâches
- ✅ Pas de crash immédiat

---

## 📦 Upload sur GitHub Release

### Prérequis

```powershell
# Dans un repo git (ex: pseudo_API)
cd C:\Users\Lenovo\Confens-IA\pseudo_API

# Vérification connexion GitHub CLI
gh auth status
```

### Upload des Deux Versions

```powershell
# Version DEBUG (pour tests)
gh release upload v1.0.1 `
    "..\scripts\launcher\dist\ConfidensIA_DEBUG.exe" `
    --clobber `
    --repo jeanmicheldanto-boop/confidensia-release

# Version PRODUCTION (pour distribution)
gh release upload v1.0.1 `
    "..\scripts\launcher\dist\ConfidensIA.exe" `
    --clobber `
    --repo jeanmicheldanto-boop/confidensia-release
```

**Note:** `--clobber` remplace les fichiers existants

### Vérification

```powershell
gh release view v1.0.1 --repo jeanmicheldanto-boop/confidensia-release | Select-String "asset.*exe"
```

**Attendu:**
```
asset:  ConfidensIA.exe
asset:  ConfidensIA_DEBUG.exe
```

---

## 🔄 Workflow Complet de Mise à Jour

### Scénario: Nouvelle Version 1.0.2

1. **Mise à jour des packages CDN**
   ```powershell
   cd C:\Users\Lenovo\Confens-IA\scripts
   .\package_cdn.ps1 -OutputDir ".\dist\cdn" -Version "1.0.2"
   ```

2. **Upload des packages sur GitHub**
   ```powershell
   cd C:\Users\Lenovo\Confens-IA\pseudo_API
   gh release create v1.0.2 --repo jeanmicheldanto-boop/confidensia-release
   gh release upload v1.0.2 ../scripts/dist/cdn/*.zip --repo jeanmicheldanto-boop/confidensia-release
   ```

3. **Mise à jour du manifeste**
   ```powershell
   cd C:\Users\Lenovo\Confens-IA\scripts\launcher
   # Éditer download_manifest.json : changer version et SHA256
   ```

4. **Recompilation du launcher**
   ```powershell
   # Version DEBUG
   ..\..\temp_venv_packaging\Scripts\pyinstaller.exe --clean --name="ConfidensIA_DEBUG" --onefile --console --icon="..\..\pseudo_UI\public\icone_cia_transp.ico" --add-data="download_manifest.json;." --add-data="logo.png;." --hidden-import="PIL._tkinter_finder" --collect-all requests --collect-all PIL --collect-all urllib3 --collect-all certifi --collect-all setuptools launcher.py
   
   # Version PRODUCTION
   ..\..\temp_venv_packaging\Scripts\pyinstaller.exe --clean --name="ConfidensIA" --onefile --windowed --icon="..\..\pseudo_UI\public\icone_cia_transp.ico" --add-data="download_manifest.json;." --add-data="logo.png;." --hidden-import="PIL._tkinter_finder" --collect-all requests --collect-all PIL --collect-all urllib3 --collect-all certifi --collect-all setuptools launcher.py
   ```

5. **Test local**
   ```powershell
   .\dist\ConfidensIA_DEBUG.exe
   ```

6. **Upload sur GitHub**
   ```powershell
   cd ..\..\pseudo_API
   gh release upload v1.0.2 "..\scripts\launcher\dist\ConfidensIA.exe" "..\scripts\launcher\dist\ConfidensIA_DEBUG.exe" --repo jeanmicheldanto-boop/confidensia-release
   ```

---

## 🎓 Leçons Apprises

### 1. L'Environnement de Compilation est CRITIQUE

❌ **Erreur courante:** Compiler avec Python système ou `.venv` minimal  
✅ **Bonne pratique:** Toujours compiler avec `temp_venv_packaging`

### 2. --collect-all vs --hidden-import

- `--hidden-import` : Importe un module spécifique
- `--collect-all` : Importe un package **et tous ses sous-modules** (recommandé pour requests, PIL)

### 3. PyInstaller Onefile vs Onedir

**Onefile** (choisi) :
- ✅ Un seul .exe facile à distribuer
- ✅ Pas de dossier DLL à gérer
- ❌ Extraction dans %TEMP% à chaque lancement (~200ms overhead)

**Onedir** (non choisi) :
- ✅ Lancement légèrement plus rapide
- ❌ Dossier de 50+ fichiers à distribuer
- ❌ Confusion pour utilisateurs

### 4. Console vs Windowed

**Toujours** créer les deux versions :
- **DEBUG** (`--console`) : Pour développement et support client
- **PRODUCTION** (`--windowed`) : Pour utilisateurs finaux

---

## 📚 Références

- PyInstaller Documentation: https://pyinstaller.org/
- GitHub CLI: https://cli.github.com/
- Python zipfile: https://docs.python.org/3/library/zipfile.html
- Tkinter: https://docs.python.org/3/library/tkinter.html
- Pillow (PIL): https://pillow.readthedocs.io/

---

## 🆘 Troubleshooting

### Launcher Ne Démarre Pas

1. Tester version DEBUG pour voir les logs
2. Vérifier que `requests` est embarqué : taille > 25 MB
3. Vérifier présence du manifeste : `pyinstaller --log-level DEBUG`

### Splash Screen Ne S'Affiche Pas

1. Vérifier que `logo.png` existe dans `scripts/launcher/`
2. Vérifier flag `--add-data="logo.png;."`
3. Vérifier que PIL est embarqué : `--collect-all PIL`

### Téléchargement Échoue

1. Vérifier URLs dans `download_manifest.json`
2. Vérifier connexion internet
3. Vérifier que release GitHub existe et est publique

### Extraction Bloquée

1. **Normal pour gros fichiers !** Le modèle (662 MB) prend 2-5 minutes
2. Surveiller activité disque dans Gestionnaire des tâches
3. Version DEBUG montre progression : `[DEBUG] Extraction titibongbong...`

---

**Dernière mise à jour:** 12 décembre 2025  
**Auteur:** Équipe ConfidensIA  
**Version Launcher:** 1.0.1 (26.61 MB)
