# 🚀 OAuth - Guide de Démarrage Rapide

## ✅ Tout est configuré !

Votre système OAuth est maintenant opérationnel avec :

- ✅ **Backend OAuth local** démarré et fonctionnel
- ✅ **Google OAuth** via Device Flow (fonctionne sur Windows !)
- ✅ **GitHub OAuth** via WebView
- ✅ **Email/Mot de passe** toujours disponible

## 🎯 Utilisation dans Notilus

### 1. Ouvrir les paramètres
- Cliquez sur l'icône **Paramètres** dans la sidebar
- Allez dans la section **"Compte"**

### 2. Se connecter
- Cliquez sur **"Se connecter"**
- Choisissez votre méthode :
  - **Google** : Affichera un code de vérification (Device Flow)
  - **GitHub** : Ouvrira votre navigateur pour l'authentification
  - **Email** : Formulaire classique email/mot de passe

### 3. Après connexion
- Vos configurations seront automatiquement synchronisées avec Firebase
- Vous pourrez les restaurer sur d'autres appareils

## 🔧 Vérification rapide

### Backend fonctionne ?
```bash
curl http://localhost:8000/api/oauth/config
```

Devrait retourner :
```json
{
  "github_configured": true,
  "google_configured": true,
  "github_client_id": "xxxxx...",
  "google_client_id": "xxxxx..."
}
```

### Dans Notilus
- Allez dans **Paramètres > Compte**
- Si le backend est démarré, les boutons Google et GitHub seront actifs
- Si le backend n'est pas démarré, seul le bouton Email sera disponible

## 📝 Notes importantes

- **Le backend doit être démarré** pour que Google et GitHub fonctionnent
- **Le backend peut être arrêté** après l'authentification (Firebase gère la session)
- **Les tokens restent locaux** - ils ne quittent jamais votre machine
- **Le fichier `.env`** contient vos secrets - ne le partagez jamais

## 🐛 Dépannage

### Les boutons Google/GitHub ne sont pas actifs
- Vérifiez que le backend est démarré : `python backend/main.py`
- Vérifiez les logs du backend pour les erreurs
- Vérifiez que le fichier `.env` est correctement configuré

### Erreur "Backend OAuth local non disponible"
- Le backend n'est pas démarré ou n'est pas accessible
- Vérifiez que le port 8000 n'est pas utilisé par un autre processus
- Redémarrez le backend

### Google Device Flow ne fonctionne pas
- Vérifiez que `GOOGLE_CLIENT_ID` et `GOOGLE_CLIENT_SECRET` sont dans `.env`
- Vérifiez que l'application OAuth est de type "Application de bureau" dans Google Console

### GitHub OAuth ne fonctionne pas
- Vérifiez que `GITHUB_CLIENT_ID` et `GITHUB_CLIENT_SECRET` sont dans `.env`
- Vérifiez que l'URL de callback est : `http://localhost:8000/api/oauth/github/callback`

---

**Tout est prêt ! Profitez de l'authentification OAuth dans Notilus ! 🎉**

