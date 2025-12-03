# Python Embarqué pour Notilus Backend

Ce système utilise un Python embarqué (portable) pour lancer le backend de manière autonome, sans nécessiter d'installation Python sur le système.

## 🚀 Configuration Initiale

### Méthode 1 : Script automatique (recommandé)

```bash
cd backend
python setup_embedded_python.py
```

Ou double-cliquez sur `setup_embedded_python.bat`

### Méthode 2 : Manuel

1. Téléchargez Python embeddable depuis https://www.python.org/downloads/
   - Version recommandée : Python 3.10.11
   - Fichier : `python-3.10.11-embed-amd64.zip`

2. Extrayez dans `backend/python_embedded/`

3. Activez pip en modifiant `python_embedded/python310._pth` :
   - Décommentez la ligne `#import site` → `import site`

4. Installez pip :
   ```bash
   python_embedded\python.exe python_embedded\get-pip.py
   ```

5. Installez les dépendances :
   ```bash
   python_embedded\python.exe -m pip install -r requirements.txt
   ```

6. Créez pythonw.exe pour mode furtif :
   ```bash
   copy python_embedded\python.exe python_embedded\pythonw.exe
   ```

## 📁 Structure

```
backend/
  ├── python_embedded/          # Python embarqué
  │   ├── python.exe            # Python standard
  │   ├── pythonw.exe           # Python furtif (sans console)
  │   ├── python310._pth        # Configuration (import site activé)
  │   ├── Scripts/              # Pip et scripts
  │   └── Lib/                  # Bibliothèques installées
  ├── main.py                   # Script principal du backend
  ├── requirements.txt          # Dépendances
  └── setup_embedded_python.py  # Script de configuration
```

## 🔇 Mode Furtif

Le backend utilise `pythonw.exe` qui lance Python sans console ni fenêtre visible. Le processus tourne en arrière-plan de manière totalement transparente.

## 🎯 Utilisation dans Flutter

Le service `BackendProcessService` détecte automatiquement :
1. `notilus_backend.exe` (si compilé avec PyInstaller)
2. `python_embedded/pythonw.exe` (Python embarqué furtif) ⭐ **Préféré**
3. `python_embedded/python.exe` (Python embarqué standard)
4. `pythonw` système (fallback)

## 📦 Pour le Build Flutter

Pour inclure le Python embarqué dans le build Flutter :

1. **En développement** : Le Python embarqué doit être dans `backend/python_embedded/`

2. **En production** : Copiez le dossier `python_embedded/` et `main.py` à côté de l'exe Flutter :
   ```
   build/windows/x64/runner/Release/
   ├── notilus.exe
   ├── main.py
   └── python_embedded/
       ├── pythonw.exe
       └── ...
   ```

Ou ajoutez-les dans `pubspec.yaml` comme assets (pour qu'ils soient inclus automatiquement).

## ✅ Avantages

- ✅ **Autonome** : Pas besoin d'installer Python sur le système
- ✅ **Furtif** : Aucune console ni fenêtre visible
- ✅ **Portable** : Fonctionne sur n'importe quelle machine Windows
- ✅ **Léger** : Python embarqué est minimal (~10-15 MB)
- ✅ **Isolé** : Ne pollue pas l'environnement Python système

## 🔧 Dépannage

### Le backend ne démarre pas

- Vérifiez que `python_embedded/pythonw.exe` existe
- Vérifiez que `main.py` est accessible
- Vérifiez les logs dans `BackendProcessService`

### Les dépendances manquent

```bash
python_embedded\python.exe -m pip install -r requirements.txt
```

### Pip n'est pas disponible

1. Vérifiez que `python310._pth` contient `import site` (pas `#import site`)
2. Réinstallez pip :
   ```bash
   python_embedded\python.exe python_embedded\get-pip.py
   ```

