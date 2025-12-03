═══════════════════════════════════════════════════════════════════════════════
                    NOTILUS BROWSER - GUIDE D'INSTALLATION
═══════════════════════════════════════════════════════════════════════════════

Version: 1.0.0
Navigateur futuriste pour développeurs et utilisateurs avancés

═══════════════════════════════════════════════════════════════════════════════
                            PRÉSENTATION
═══════════════════════════════════════════════════════════════════════════════

Notilus Browser est un navigateur web de nouvelle génération, spécialement 
conçu pour les développeurs et les utilisateurs avancés. Il combine une 
interface utilisateur futuriste de style science-fiction avec des outils de 
développement intégrés, offrant une expérience de navigation unique et 
professionnelle.

Basé sur Flutter Desktop et Microsoft WebView2, Notilus Browser offre des 
performances natives exceptionnelles tout en conservant la compatibilité 
complète avec les standards web modernes.

═══════════════════════════════════════════════════════════════════════════════
                        CARACTÉRISTIQUES PRINCIPALES
═══════════════════════════════════════════════════════════════════════════════

🎨 INTERFACE UTILISATEUR
   • Design GX futuriste avec effets néon et glassmorphism
   • Thèmes personnalisables (Rouge Notilus, Bleu Cyber, Vert Matrix, etc.)
   • Transparence et effets visuels avancés
   • Arrière-plans animés avec particules

🌐 NAVIGATION ET ONGLETS
   • Système d'onglets avancé avec regroupement intelligent
   • Barre d'adresse futuriste avec suggestions intelligentes
   • Mode privé/incognito complet
   • Navigation avant/arrière et rechargement rapide
   • Splitscreen multiple pour comparer plusieurs pages

🛠️ OUTILS DE DÉVELOPPEMENT INTÉGRÉS
   • DevTools natifs (Console, Network, Elements, Performance, Application)
   • Notilus Studio - Tests front-end avancés
   • Notilus Lighthouse - Analyse de performance et audits
   • Terminal intégré (PowerShell, CMD, WSL)
   • Backend Lab - Test et analyse d'API avec IA

🧩 FONCTIONNALITÉS AVANCÉES
   • Système de Mosaïque - Organisation visuelle de workspace
   • Extensions avec runtime basique
   • Bloqueur de publicités intégré
   • Gestion avancée des cookies et de l'historique
   • Synchronisation via Firebase (optionnelle)

☁️ SERVICES WEB INTÉGRÉS
   • Accès rapide à YouTube, YouTube Music
   • ChatGPT, DeepSeek (IA conversationnelle)
   • WhatsApp Web, Telegram
   • Et bien plus encore...

═══════════════════════════════════════════════════════════════════════════════
                              PRÉREQUIS
═══════════════════════════════════════════════════════════════════════════════

SYSTÈME D'EXPLOITATION
   • Windows 10 (version 1809 ou supérieure) 64-bit
   • Windows 11 (toutes versions) 64-bit

COMPOSANTS REQUIS
   • Microsoft WebView2 Runtime (recommandé)
     → Vérifié automatiquement lors de l'installation
     → Téléchargement disponible si nécessaire :
       https://developer.microsoft.com/microsoft-edge/webview2/

ESPACE DISQUE
   • Minimum : 200 MB pour l'installation
   • Recommandé : 500 MB pour les mises à jour futures

PERMISSIONS
   • Droits d'utilisateur standard (pas d'administrateur requis)
   • Accès réseau pour les mises à jour et la synchronisation

═══════════════════════════════════════════════════════════════════════════════
                          INSTALLATION
═══════════════════════════════════════════════════════════════════════════════

ÉTAPES D'INSTALLATION

1. VÉRIFICATION DES PRÉREQUIS
   L'installateur vérifie automatiquement la présence de Microsoft WebView2 
   Runtime. Si celui-ci n'est pas détecté, vous serez informé et pourrez 
   continuer l'installation ou l'installer manuellement.

2. SÉLECTION DU RÉPERTOIRE
   Par défaut, Notilus Browser sera installé dans :
   C:\Program Files\Notilus Browser
   
   Vous pouvez choisir un autre emplacement si nécessaire.

3. OPTIONS D'INSTALLATION
   • Créer une icône sur le Bureau (optionnel)
   • Créer un raccourci dans le menu Démarrer (optionnel)
   • Créer une icône dans la barre de lancement rapide (optionnel)
   • Associer Notilus Browser comme navigateur par défaut (optionnel)

4. INSTALLATION
   Les fichiers seront copiés et l'application sera configurée automatiquement.

5. LANCEMENT
   Vous pouvez lancer Notilus Browser immédiatement après l'installation.

═══════════════════════════════════════════════════════════════════════════════
                        ARCHITECTURE TECHNIQUE
═══════════════════════════════════════════════════════════════════════════════

STACK TECHNIQUE

Frontend
   • Framework : Flutter Desktop
   • Langage : Dart
   • UI : Material Design 3 avec composants personnalisés

Moteur de Rendu
   • Microsoft WebView2 (Chromium Embedded Framework)
   • Compatibilité : Standards web modernes (HTML5, CSS3, ES2020+)
   • Performance : Optimisé pour Windows

Backend
   • API : FastAPI (Python)
   • Format : Exécutable standalone (notilus-backend.exe)
   • Services : Monitoring, détection, Backend Lab

Stockage
   • Local : SQLite pour l'historique et les données
   • Cloud : Firebase (optionnel) pour la synchronisation

═══════════════════════════════════════════════════════════════════════════════
                        COMPOSANTS INSTALLÉS
═══════════════════════════════════════════════════════════════════════════════

L'installation inclut :

✓ Application principale (notilus.exe)
✓ Backend API standalone (notilus-backend.exe)
✓ Bibliothèques Flutter et dépendances
✓ Assets et ressources de l'interface
✓ Icônes et images
✓ Fichiers de configuration

Note : Python n'est PAS requis. Le backend est un exécutable standalone 
compilé qui fonctionne indépendamment.

═══════════════════════════════════════════════════════════════════════════════
                          PREMIER DÉMARRAGE
═══════════════════════════════════════════════════════════════════════════════

LORS DU PREMIER LANCEMENT

1. Écran de démarrage
   Notilus Browser affiche un écran de démarrage avec animation pendant 
   l'initialisation.

2. Configuration initiale
   • Acceptation des conditions d'utilisation (si applicable)
   • Configuration des préférences de base
   • Option de synchronisation Firebase (facultatif)

3. Interface principale
   Vous accéderez à l'interface principale avec :
   • Barre d'onglets en haut
   • Barre d'adresse centrale
   • Sidebar à gauche avec accès rapide
   • Zone de contenu principale

4. Découverte des fonctionnalités
   • Appuyez sur F12 pour ouvrir les DevTools
   • Utilisez Ctrl+Shift+M pour activer la Mosaïque
   • Explorez les paramètres pour personnaliser l'interface

═══════════════════════════════════════════════════════════════════════════════
                        RACCOURCIS CLAVIER
═══════════════════════════════════════════════════════════════════════════════

NAVIGATION
   Ctrl + T          Nouvel onglet
   Ctrl + W          Fermer l'onglet actuel
   Ctrl + Shift + T  Rouvrir le dernier onglet fermé
   Ctrl + Tab        Onglet suivant
   Ctrl + Shift + Tab Onglet précédent
   Ctrl + R          Recharger la page
   Ctrl + Shift + N  Nouvel onglet privé

OUTILS
   F12               Ouvrir/Fermer DevTools
   Ctrl + Shift + M  Activer/Désactiver la Mosaïque
   Ctrl + Shift + I  Inspecter l'élément

INTERFACE
   Ctrl + B          Afficher/Masquer la sidebar
   Ctrl + Shift + B  Afficher/Masquer la barre de favoris

═══════════════════════════════════════════════════════════════════════════════
                            SUPPORT ET AIDE
═══════════════════════════════════════════════════════════════════════════════

RESSOURCES

Documentation complète
   https://github.com/Notho-freedom/Notilus-Browser

Rapporter un problème
   https://github.com/Notho-freedom/Notilus-Browser/issues

Mises à jour
   https://github.com/Notho-freedom/Notilus-Browser/releases

Communauté
   GitHub Discussions : Discussions et questions de la communauté

═══════════════════════════════════════════════════════════════════════════════
                          DÉSINSTALLATION
═══════════════════════════════════════════════════════════════════════════════

Pour désinstaller Notilus Browser :

1. Ouvrez le Panneau de configuration Windows
2. Allez dans "Programmes et fonctionnalités"
3. Sélectionnez "Notilus Browser"
4. Cliquez sur "Désinstaller"

OU

1. Utilisez le raccourci "Désinstaller Notilus Browser" dans le menu Démarrer

Note : Vos paramètres utilisateur et préférences seront conservés dans :
%APPDATA%\Notilus Browser\

Pour une désinstallation complète, supprimez également ce dossier.

═══════════════════════════════════════════════════════════════════════════════
                            INFORMATIONS LÉGALES
═══════════════════════════════════════════════════════════════════════════════

ÉDITEUR
   Notilus Team
   https://github.com/Notho-freedom/Notilus-Browser

LICENCE
   Consultez le fichier LICENSE dans le répertoire d'installation pour les 
   détails complets de la licence.

DROITS D'AUTEUR
   Copyright (C) 2024 Notilus Team
   Tous droits réservés.

COMPOSANTS TIERS
   Notilus Browser utilise les composants open-source suivants :
   • Flutter (BSD License)
   • WebView2 (Microsoft)
   • FastAPI (MIT License)
   • Et autres dépendances listées dans les fichiers de licence

═══════════════════════════════════════════════════════════════════════════════
                            REMERCIEMENTS
═══════════════════════════════════════════════════════════════════════════════

Merci d'avoir choisi Notilus Browser !

Nous espérons que vous apprécierez cette expérience de navigation unique, 
conçue spécialement pour les développeurs et les utilisateurs avancés.

Pour toute question, suggestion ou retour, n'hésitez pas à nous contacter 
via GitHub.

Bon développement avec Notilus Browser ! 🚀

═══════════════════════════════════════════════════════════════════════════════
