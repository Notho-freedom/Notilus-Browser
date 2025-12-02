# 🚀 Build CEF - Guide étape par étape

## ✅ Étape 1 : Vérification

Vérifiez que CEF est bien installé :

```bash
# Vérifier la structure
dir notilus_cef\windows\cef\CMakeLists.txt
dir notilus_cef\windows\cef\Release\libcef.dll
dir notilus_cef\windows\cef\Resources\icudtl.dat
```

Tous ces fichiers doivent exister.

## 🔧 Étape 2 : Nettoyage (optionnel mais recommandé)

```bash
flutter clean
```

## 📦 Étape 3 : Installation des dépendances

```bash
flutter pub get
```

Cela va :
- Installer le plugin `notilus_cef`
- Générer les fichiers de registration du plugin
- Configurer CMake

## 🏗️ Étape 4 : Build

### Build Debug (pour développement)

```bash
flutter build windows --debug
```

### Build Release (pour production)

```bash
flutter build windows --release
```

**Première fois** : Le build peut prendre **5-10 minutes** car :
- CMake configure CEF
- Compilation du plugin C++
- Copie des DLLs et ressources CEF

## ✅ Étape 5 : Vérification

Après le build, vérifiez que les fichiers CEF sont copiés :

```bash
# Vérifier les DLLs
dir build\windows\x64\runner\Release\libcef.dll
dir build\windows\x64\runner\Release\chrome_elf.dll

# Vérifier les ressources
dir build\windows\x64\runner\Release\icudtl.dat
dir build\windows\x64\runner\Release\locales
```

## 🎯 Étape 6 : Test

Créez un fichier de test simple :

```dart
// test_cef.dart
import 'package:flutter/material.dart';
import 'package:notilus/widgets/browser/cef_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CefView(
          initialUrl: "https://flutter.dev",
          width: 1280,
          height: 720,
        ),
      ),
    );
  }
}
```

Lancez :

```bash
flutter run -d windows
```

## 🐛 Dépannage

### Erreur : "CEF not found"

**Solution** :
1. Vérifiez que `notilus_cef/windows/cef/CMakeLists.txt` existe
2. Vérifiez le chemin dans `notilus_cef/windows/CMakeLists.txt`

### Erreur : "libcef.dll not found" au runtime

**Solution** :
1. Vérifiez que les DLLs sont copiées dans le dossier de build
2. Vérifiez que vous lancez depuis le bon dossier (où sont les DLLs)

### Erreur de compilation C++

**Solution** :
1. Vérifiez Visual Studio 2022 avec C++ workload
2. Vérifiez CMake 3.14+
3. Nettoyez et rebuild : `flutter clean && flutter pub get && flutter build windows`

### Texture noire

**Solutions** :
1. Vérifiez que `init()` a réussi (pas d'erreur)
2. Vérifiez que l'URL est valide
3. Vérifiez les logs CEF dans la console
4. Vérifiez que les ressources sont copiées (icudtl.dat, locales, etc.)

## 📊 Performance

### Temps de build

- **Première fois** : 5-10 minutes
- **Builds suivants** : 1-3 minutes (si pas de changements C++)

### Taille de l'application

- **Sans CEF** : ~50-100 MB
- **Avec CEF** : ~300-400 MB (à cause des DLLs CEF)

## ✅ Checklist finale

- [ ] CEF extrait dans `notilus_cef/windows/cef/`
- [ ] `flutter pub get` exécuté
- [ ] Build réussi (`flutter build windows`)
- [ ] DLLs copiées dans le dossier de build
- [ ] Test avec `CefView` fonctionne

## 🎉 Prêt !

Si tout est OK, vous pouvez maintenant utiliser CEF dans votre application !

Voir `docs/CEF_SETUP.md` pour la documentation complète.

