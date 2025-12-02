# ✅ Vérification de l'installation CEF

## Checklist avant build

### 1. Structure des dossiers

Vérifiez que la structure suivante existe :

```
notilus_cef/windows/cef/
├── CMakeLists.txt          ✅ Doit exister
├── include/
│   └── cef/                ✅ Headers CEF
├── Release/
│   ├── libcef.dll          ✅ DLL principale
│   ├── chrome_elf.dll      ✅ DLL Chrome
│   ├── libEGL.dll          ✅ OpenGL ES
│   ├── libGLESv2.dll       ✅ OpenGL ES 2
│   └── ...                 ✅ Autres DLLs
└── Resources/
    ├── icudtl.dat          ✅ Données ICU
    ├── locales/            ✅ Fichiers de traduction
    └── *.pak               ✅ Ressources Chrome
```

### 2. Fichiers critiques

**DLLs (dans Release/)** :
- [ ] `libcef.dll` (environ 100-150 MB)
- [ ] `chrome_elf.dll`
- [ ] `d3dcompiler_47.dll`
- [ ] `libEGL.dll`
- [ ] `libGLESv2.dll`
- [ ] `vk_swiftshader.dll`
- [ ] `vulkan-1.dll`

**Binaires (dans Release/)** :
- [ ] `snapshot_blob.bin`
- [ ] `v8_context_snapshot.bin`
- [ ] `vk_swiftshader_icd.json`

**Ressources (dans Resources/)** :
- [ ] `icudtl.dat`
- [ ] `chrome_100_percent.pak`
- [ ] `chrome_200_percent.pak`
- [ ] `resources.pak`
- [ ] `locales/` (dossier avec ~55 fichiers .pak)

### 3. Test rapide

```bash
# Vérifier que CEF est détecté
cd notilus_cef/windows
if [ -f "cef/CMakeLists.txt" ]; then
  echo "✅ CEF détecté"
else
  echo "❌ CEF non trouvé"
fi
```

### 4. Build test

```bash
# Nettoyer
flutter clean

# Installer les dépendances
flutter pub get

# Build (première fois peut prendre 5-10 minutes)
flutter build windows --release
```

### 5. Vérifications après build

Après le build, vérifiez que les fichiers sont copiés dans :

```
build/windows/x64/runner/Release/
├── libcef.dll              ✅
├── chrome_elf.dll           ✅
├── icudtl.dat              ✅
├── locales/                ✅
└── *.pak                   ✅
```

## 🐛 Problèmes courants

### Erreur : "CEF non trouvé"
→ Vérifiez que `notilus_cef/windows/cef/CMakeLists.txt` existe

### Erreur : "libcef.dll not found"
→ Vérifiez que les DLLs sont dans `Release/` et non ailleurs

### Erreur : "icudtl.dat not found"
→ Vérifiez que `Resources/icudtl.dat` existe

### Build échoue avec erreurs de linking
→ Vérifiez Visual Studio 2022 avec C++ workload installé

## ✅ Tout est OK ?

Si tous les fichiers sont présents, vous pouvez builder !

```bash
flutter build windows --release
```

Ensuite, testez avec le widget `CefView` dans votre app Flutter.

