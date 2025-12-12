# ConfidensIA Release Repository

Ce repository contient les **scripts de packaging et compilation** pour créer les distributions de ConfidensIA.

## 📦 Contenu

### Scripts de Packaging

- **`scripts/package_cdn.ps1`** - Crée les packages ZIP pour distribution CDN
  - Python embedded
  - Dependencies bundle (95 packages)
  - pseudo_API (FastAPI backend)
  - pseudo_UI (Next.js frontend)
  - laplume (NER module)
  - titibongbong-fp16 (modèle)

### Scripts Launcher

- **`scripts/launcher/build_launcher.ps1`** - Compile le launcher Windows (PyInstaller)
  - Version DEBUG (avec console)
  - Version PRODUCTION (sans console)
  - Upload automatique sur GitHub Release

### Documentation

- **`docs/GUIDE_COMPILATION_LAUNCHER.md`** - Guide complet de compilation du launcher
  - Prérequis et environnement
  - Commandes de compilation
  - Troubleshooting
  - Workflow de mise à jour

## 🚀 Quick Start

### 1. Créer les Packages CDN

```powershell
cd scripts
.\package_cdn.ps1 -OutputDir ".\dist\cdn" -Version "1.0.1"
```

### 2. Compiler le Launcher

```powershell
cd scripts\launcher
.\build_launcher.ps1 -Version "1.0.1"
```

### 3. Upload sur GitHub Release

Les scripts proposent automatiquement l'upload sur GitHub Release `jeanmicheldanto-boop/confidensia-release`.

## 📋 Structure des Releases

Chaque release contient :

| Asset | Taille | Description |
|-------|--------|-------------|
| `ConfidensIA.exe` | 26 MB | Launcher production (sans console) |
| `ConfidensIA_DEBUG.exe` | 26 MB | Launcher debug (avec console) |
| `python-3.11.9-embed-amd64.zip` | 11 MB | Python embedded |
| `dependencies-bundle-v1.0.0.zip` | 382 MB | 95 packages Python |
| `pseudo_API-src-v1.0.X.zip` | 2 MB | Backend FastAPI |
| `pseudo_UI-out-v1.0.X.zip` | 70 MB | Frontend Next.js |
| `laplume-src-v1.0.X.zip` | 5 MB | Module NER |
| `titibongbong-fp16-v1.0.X.zip` | 662 MB | Modèle NER |

**Total:** ~1.1 GB

## 🔧 Prérequis

- Windows 10/11
- PowerShell 5.1+
- Python 3.11.9 ou 3.13.7 (dans `temp_venv_packaging`)
- GitHub CLI (`gh`)
- Git

## 📚 Documentation

Voir [`docs/GUIDE_COMPILATION_LAUNCHER.md`](docs/GUIDE_COMPILATION_LAUNCHER.md) pour la documentation complète.

## 🏗️ Architecture

```
ConfidensIA Release
├── scripts/
│   ├── package_cdn.ps1           # Packaging CDN
│   └── launcher/
│       └── build_launcher.ps1    # Compilation launcher
├── docs/
│   └── GUIDE_COMPILATION_LAUNCHER.md
└── README.md
```

## 🔄 Workflow de Release

1. **Mise à jour du code** dans les repos `pseudo_api`, `pseudo_ui`, `laplume_test`
2. **Packaging** avec `package_cdn.ps1`
3. **Création release GitHub** `v1.0.X`
4. **Upload packages** sur la release
5. **Mise à jour manifeste** dans `launcher/download_manifest.json`
6. **Compilation launcher** avec `build_launcher.ps1`
7. **Upload launcher** sur la release
8. **Test sur PC tiers** avec version DEBUG

## 📝 Notes de Version

### v1.0.1 (12 décembre 2025)

✅ **Correctifs:**
- Sécurité: Remplacement `SUPABASE_SERVICE_KEY` → `SUPABASE_ANON_KEY`
- Packaging: Inclusion du fichier `.env` dans distribution
- Launcher: Embarquement des dépendances `requests`, `PIL`, `urllib3`, `certifi`, `setuptools`

✅ **Améliorations:**
- Documentation complète de compilation
- Scripts automatisés de build
- Version DEBUG avec console pour support

🐛 **Bugs connus:**
- Launcher 6 MB plus petit que v1.0.0 (modules de test setuptools non embarqués, non critique)

## 🆘 Support

Pour les problèmes de compilation ou packaging, consulter :
1. [`docs/GUIDE_COMPILATION_LAUNCHER.md`](docs/GUIDE_COMPILATION_LAUNCHER.md) - Section Troubleshooting
2. Issues GitHub de ce repository
3. Logs de compilation dans `scripts/launcher/build/`

## 🔒 Sécurité

Tous les fichiers incluent des checksums SHA256 pour vérifier leur intégrité.

---

**ConfensIA** - Pseudonymisation locale et sécurisée  
© 2025 - Version actuelle: **1.0.1**
