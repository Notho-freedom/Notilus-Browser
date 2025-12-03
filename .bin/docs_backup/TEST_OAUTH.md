# Test de l'OAuth Backend

## ✅ Vérification rapide

### 1. Vérifier que le backend est démarré

```bash
curl http://localhost:8000/api/health
```

Devrait retourner : `{"status":"healthy","service":"notilus-api"}`

### 2. Vérifier l'endpoint OAuth config

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

### 3. Si vous obtenez "Not Found"

**Le backend doit être redémarré** après modification du code :

1. Arrêtez le backend (Ctrl+C)
2. Redémarrez-le : `cd backend && python main.py`
3. Vérifiez à nouveau avec `curl`

### 4. Tester depuis Notilus

1. Ouvrez Notilus
2. Allez dans **Paramètres > Compte**
3. Cliquez sur **"Se connecter"**
4. Vous devriez voir les boutons Google et GitHub (si le backend est configuré)

### 5. Debug

Si le backend n'est pas détecté :

- Vérifiez les logs du backend pour les erreurs
- Vérifiez que le fichier `.env` contient bien les valeurs (pas `your_github_client_id`)
- Vérifiez que le port 8000 n'est pas utilisé par un autre processus
- Vérifiez les logs Flutter dans la console pour voir les messages de debug

