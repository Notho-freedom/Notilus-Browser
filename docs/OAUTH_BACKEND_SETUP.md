# Configuration OAuth avec Backend Local

## 🎯 Vue d'ensemble

Notilus utilise un **backend local** (Python/FastAPI) pour gérer l'authentification OAuth de manière unifiée sur toutes les plateformes, y compris Windows.

## ✅ Avantages

- ✅ **Google OAuth fonctionne sur Windows** via Device Flow
- ✅ **GitHub OAuth fonctionne partout** via WebView
- ✅ **Tout reste local** - les tokens ne quittent pas votre machine
- ✅ **Cross-platform** - même code pour toutes les plateformes

## 📋 Prérequis

1. Python 3.8+ installé
2. Backend Notilus configuré (voir `backend/README.md`)
3. Comptes développeur pour GitHub et/ou Google OAuth

---

## 🔧 Configuration

### 1. Installer les dépendances

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configurer GitHub OAuth

1. Allez sur https://github.com/settings/developers
2. Cliquez sur "New OAuth App"
3. Remplissez:
   - **Application name**: Notilus Browser
   - **Homepage URL**: `http://localhost:8000`
   - **Authorization callback URL**: `http://localhost:8000/api/oauth/github/callback`
4. Copiez le **Client ID** et **Client Secret**

### 3. Configurer Google OAuth

1. Allez sur https://console.cloud.google.com/apis/credentials
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez l'API "Google+ API" (si nécessaire)
4. Créez des identifiants OAuth 2.0:
   - Type: **Application de bureau**
   - Nom: Notilus Browser
5. Copiez le **Client ID** et **Client Secret**

### 4. Créer le fichier `.env`

**Note** : Le fichier `.env` est ignoré par Git (pour la sécurité). Il a été créé automatiquement depuis `.env.example`.

Si vous ne voyez pas le fichier `.env` dans votre explorateur de fichiers, c'est normal - les fichiers commençant par `.` sont souvent cachés. Vous pouvez :

1. **Utiliser un éditeur de texte** (VS Code, Notepad++, etc.) et ouvrir directement `backend/.env`
2. **Ou le créer manuellement** en copiant `backend/.env.example` vers `backend/.env`

Ensuite, remplissez les valeurs :

```env
GITHUB_CLIENT_ID=votre_github_client_id
GITHUB_CLIENT_SECRET=votre_github_client_secret
GOOGLE_CLIENT_ID=votre_google_client_id
GOOGLE_CLIENT_SECRET=votre_google_client_secret
```

---

## 🚀 Démarrage

### Démarrer le backend

```bash
cd backend
python main.py
```

Le backend sera accessible sur `http://localhost:8000`

### Vérifier que le backend fonctionne

Ouvrez Notilus et allez dans **Paramètres > Compte**. Si le backend est disponible, les boutons Google et GitHub seront actifs.

---

## 🔄 Flux d'authentification

### Google (Device Flow)

1. L'utilisateur clique sur "Continuer avec Google"
2. Le backend génère un **device code** et un **user code**
3. Une fenêtre s'ouvre avec le code de vérification
4. L'utilisateur ouvre `https://www.google.com/device` et entre le code
5. L'app poll le backend toutes les X secondes
6. Une fois autorisé, le backend récupère le token
7. Le token est utilisé pour se connecter à Firebase

### GitHub (WebView Flow)

1. L'utilisateur clique sur "Continuer avec GitHub"
2. Le backend génère une URL d'autorisation GitHub
3. Une fenêtre du navigateur s'ouvre avec GitHub
4. L'utilisateur se connecte et autorise l'application
5. GitHub redirige vers `http://localhost:8000/api/oauth/github/callback`
6. Le backend échange le code contre un token
7. L'app poll le backend pour récupérer le token
8. Le token est utilisé pour se connecter à Firebase

---

## 🐛 Dépannage

### Le backend ne démarre pas

- Vérifiez que Python 3.8+ est installé
- Vérifiez que toutes les dépendances sont installées: `pip install -r requirements.txt`
- Vérifiez que le port 8000 n'est pas utilisé par un autre processus

### "Backend OAuth local non disponible"

- Vérifiez que le backend est démarré: `python backend/main.py`
- Vérifiez que le backend est accessible: `curl http://localhost:8000/api/oauth/config`
- Vérifiez les logs du backend pour les erreurs

### Google Device Flow ne fonctionne pas

- Vérifiez que `GOOGLE_CLIENT_ID` et `GOOGLE_CLIENT_SECRET` sont correctement configurés dans `.env`
- Vérifiez que l'application OAuth est de type "Application de bureau" dans Google Console
- Vérifiez que l'API "Google+ API" est activée

### GitHub OAuth ne fonctionne pas

- Vérifiez que `GITHUB_CLIENT_ID` et `GITHUB_CLIENT_SECRET` sont correctement configurés dans `.env`
- Vérifiez que l'URL de callback est exactement: `http://localhost:8000/api/oauth/github/callback`
- Vérifiez que GitHub OAuth est activé dans Firebase Console (si vous utilisez Firebase)

---

## 📝 Notes

- Le backend doit être démarré **avant** d'utiliser l'authentification OAuth
- Les tokens OAuth sont stockés temporairement dans le backend (en mémoire)
- Une fois l'authentification réussie, Firebase gère la session
- Le backend peut être arrêté après l'authentification (mais la synchronisation nécessite Firebase)

---

## 🔒 Sécurité

- Ne partagez **jamais** votre fichier `.env`
- Les tokens OAuth transitent uniquement entre l'app et le backend local
- Le backend n'est accessible que depuis `localhost` (127.0.0.1)
- Les tokens sont stockés en mémoire et ne persistent pas après redémarrage

