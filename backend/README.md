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

## TODO

- Intégration Firebase complète
- Implémentation des services réels
- Authentification et sécurité
- WebSockets pour communication temps réel

