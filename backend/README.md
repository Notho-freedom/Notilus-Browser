# Notilus Browser - Backend API

API backend pour le navigateur Notilus, fournissant des services pour le monitoring, la détection, l'injection, l'automatisation et l'IA.

## Installation

```bash
pip install -r requirements.txt
```

## Configuration

Copiez `.env.example` vers `.env` et configurez les variables d'environnement.

## Démarrage

```bash
python main.py
```

L'API sera accessible sur `http://localhost:8000`

## Build de l'exécutable

Pour créer un exécutable Windows avec Python 3.11 (version recommandée pour la compatibilité) :

### Windows

```bash
cd backend
build_backend.bat
```

Le script utilise automatiquement Python 3.11 (`py -3.11`) pour garantir la meilleure compatibilité. L'exécutable sera généré dans `dist/notilus-backend.exe`.

### Linux/macOS

```bash
cd backend
chmod +x build_backend.sh
./build_backend.sh
```

Le script utilise automatiquement Python 3.11 pour garantir la meilleure compatibilité. L'exécutable sera généré dans `dist/notilus-backend`.

### Utilisation du fichier .spec (optionnel)

Pour un contrôle plus avancé, vous pouvez utiliser directement le fichier `.spec` :

```bash
# Windows
py -3.11 -m PyInstaller notilus-backend.spec

# Linux/macOS
python3.11 -m PyInstaller notilus-backend.spec
```

**Note importante** : Le build est configuré pour utiliser Python 3.11 par défaut, qui offre une meilleure compatibilité que Python 3.13 pour les dépendances actuelles.

## Documentation

Une fois le serveur démarré, la documentation interactive est disponible sur :
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Services

- **Monitoring**: Métriques et performances
- **Detection**: Détection de menaces et vulnérabilités
- **Injection**: Injection de scripts et CSS
- **Automation**: Automatisation de tâches
- **AI**: Services d'intelligence artificielle

## 🐙 Backend Lab - Système de tests backend ultra-avancé

Le Backend Lab est un écosystème complet pour tester et analyser des APIs backend.

### Fonctionnalités principales

#### 🔍 Server Discovery
- Détection automatique des serveurs locaux par scan de ports
- Fingerprinting de frameworks (FastAPI, Express, Django, Spring Boot, etc.)
- Analyse des processus et ports en écoute
- Health checks automatiques

**Endpoints:**
- `POST /api/backend-lab/servers/scan` - Scanner les serveurs locaux
- `GET /api/backend-lab/servers` - Lister tous les serveurs découverts
- `GET /api/backend-lab/servers/{server_id}` - Détails d'un serveur
- `POST /api/backend-lab/servers/{server_id}/refresh` - Rafraîchir les infos
- `POST /api/backend-lab/servers` - Ajouter un serveur manuellement

#### 🗺️ Route Discovery
- Découverte automatique des routes via OpenAPI/Swagger
- Introspection GraphQL
- Fuzzing intelligent de routes communes
- Détection automatique des paramètres (path, query, body)

**Endpoints:**
- `POST /api/backend-lab/routes/discover/{server_id}` - Découvrir les routes
- `GET /api/backend-lab/routes/{server_id}` - Lister les routes d'un serveur
- `GET /api/backend-lab/routes/{server_id}/{route_id}` - Détails d'une route
- `POST /api/backend-lab/routes/{server_id}/import` - Importer OpenAPI

#### ⚙️ Auto Configuration
- Configuration automatique basée sur le serveur cible sélectionné
- Découverte automatique des routes
- Détection automatique des paramètres
- Création automatique de tests

**Endpoints:**
- `POST /api/backend-lab/auto-config/servers/{server_id}/configure` - Configurer automatiquement
- `GET /api/backend-lab/auto-config/servers/{server_id}/config` - Récupérer la config
- `POST /api/backend-lab/auto-config/servers/{server_id}/detect-parameters` - Détecter les paramètres

#### 🧪 API Testing
- Tests fonctionnels avec assertions avancées
- Variables dynamiques et extraction
- Collections de tests
- Environnements de test

**Endpoints:**
- `POST /api/backend-lab/tests/run` - Test rapide
- `POST /api/backend-lab/tests` - Créer un test
- `GET /api/backend-lab/tests` - Lister les tests
- `POST /api/backend-lab/tests/{test_id}/run` - Exécuter un test
- `POST /api/backend-lab/tests/collections` - Créer une collection

#### 💉 Interception
- Capture de requêtes HTTP
- Modification et replay
- Scénarios enregistrés

#### 🛡️ Security Scanner
- Tests de sécurité OWASP
- Détection de vulnérabilités
- Rapports de sécurité

#### ⚡ Performance Lab
- Tests de charge
- Tests de stress
- Métriques de performance

#### 📊 Analytics
- Dashboards et statistiques
- Rapports détaillés
- Tendances et métriques

### Utilisation

1. **Découvrir un serveur:**
   ```bash
   POST /api/backend-lab/servers/scan
   ```

2. **Sélectionner un serveur cible et configurer automatiquement:**
   ```bash
   POST /api/backend-lab/auto-config/servers/{server_id}/configure
   ```
   Cette opération va automatiquement:
   - Découvrir toutes les routes du serveur
   - Détecter les paramètres de chaque route
   - Créer des tests automatiques

3. **Tester les routes découvertes:**
   ```bash
   POST /api/backend-lab/tests/{test_id}/run
   ```

### Notes importantes

- **Aucune simulation**: Le Backend Lab travaille uniquement avec des serveurs réels. Toute fonctionnalité de simulation a été supprimée.
- **Validation stricte**: Les IDs de serveurs sont validés pour rejeter les placeholders comme `{server_id}` et les tentatives d'injection.
- **Configuration automatique**: Quand un serveur cible est sélectionné, tout se configure automatiquement (routes, tests, paramètres).

## TODO

- Intégration Firebase complète
- Implémentation des services réels
- Authentification et sécurité
- WebSockets pour communication temps réel
