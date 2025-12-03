# Extensions

Système d'extensions pour personnaliser et étendre Notilus.

## Installation

1. Accédez aux Extensions via la sidebar
2. Cliquez sur "Installer une extension"
3. Sélectionnez le fichier manifest.json
4. L'extension sera installée et activée

## Développement

Les extensions Notilus utilisent un format de manifest similaire à Chrome :

```json
{
  "name": "Mon Extension",
  "version": "1.0.0",
  "manifest_version": 2,
  "permissions": ["tabs", "storage"],
  "background": {
    "scripts": ["background.js"]
  },
  "content_scripts": [{
    "matches": ["<all_urls>"],
    "js": ["content.js"]
  }]
}
```

## API disponible

- `chrome.tabs` : Gestion des onglets
- `chrome.storage` : Stockage local
- `chrome.runtime` : Communication avec le background
- API Notilus spécifiques

## Raccourcis

- `Ctrl+Shift+E` : Ouvrir le panneau Extensions

