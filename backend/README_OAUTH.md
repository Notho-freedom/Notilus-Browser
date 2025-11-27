# Configuration OAuth - Guide Rapide

## 📁 Fichiers créés

- ✅ `.env.example` - Template de configuration (visible dans Git)
- ✅ `.env` - Votre configuration réelle (ignoré par Git pour la sécurité)

## 🔧 Configuration rapide

1. **Ouvrez le fichier `backend/.env`** dans un éditeur de texte
   - Si vous ne le voyez pas, c'est normal : les fichiers `.env` sont souvent cachés
   - Utilisez VS Code ou un autre éditeur pour l'ouvrir directement

2. **Remplissez les valeurs** :

### Pour GitHub :
- Allez sur https://github.com/settings/developers
- Créez une nouvelle OAuth App
- Callback URL : `http://localhost:8000/api/oauth/github/callback`
- Copiez le Client ID et Client Secret

### Pour Google :
- Allez sur https://console.cloud.google.com/apis/credentials
- Créez des identifiants OAuth 2.0 (type "Application de bureau")
- Copiez le Client ID et Client Secret

3. **Remplacez dans `.env`** :
```env
GITHUB_CLIENT_ID=votre_vrai_client_id
GITHUB_CLIENT_SECRET=votre_vrai_client_secret
GOOGLE_CLIENT_ID=votre_vrai_client_id
GOOGLE_CLIENT_SECRET=votre_vrai_client_secret
```

## 🚀 Démarrage

```bash
cd backend
python main.py
```

Le backend sera accessible sur `http://localhost:8000`

## ✅ Vérification

Dans Notilus, allez dans **Paramètres > Compte**. Si le backend est démarré et configuré, les boutons Google et GitHub seront actifs.

## 📝 Note importante

Le fichier `.env` contient des secrets et ne doit **jamais** être partagé ou commité dans Git. C'est pourquoi il est dans `.gitignore`.

