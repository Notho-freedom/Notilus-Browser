# 🛡️ Guide de Test du Bloqueur de Publicités Notilus

## Comment vérifier que le bloqueur fonctionne ?

### 1. **Vérification visuelle dans l'interface**

#### Dans la barre d'adresse (GXAddressBar)
- ✅ **Icône shield (bouclier)** visible à droite de la barre d'adresse
- ✅ **Bordure rouge** autour de l'icône = bloqueur **ACTIVÉ**
- ✅ **Pas de bordure** = bloqueur **DÉSACTIVÉ**
- ✅ **Survol de l'icône** : affiche le nombre de requêtes bloquées

#### Exemple de tooltip :
```
Bloqueur de pubs activé (42 bloquées)
Cliquer pour désactiver
```

### 2. **Vérification dans la console du navigateur**

1. Ouvrez les **DevTools** (F12)
2. Allez dans l'onglet **Console**
3. Vous devriez voir :
   ```
   [Notilus AdBlocker] 🛡️ Activé - Protection active
   ```
4. Quand une pub est bloquée :
   ```
   [Notilus AdBlocker] 🛡️ Bloqué #1: https://doubleclick.net/...
   [Notilus AdBlocker] 🛡️ Bloqué #2: https://googlesyndication.com/...
   [Notilus AdBlocker] 🧹 Nettoyé 3 élément(s) publicitaire(s)
   ```

### 3. **Sites de test recommandés**

#### Sites avec beaucoup de publicités (pour tester) :
- **Forbes.com** - Beaucoup de pubs
- **CNN.com** - Bannières publicitaires
- **YouTube.com** - Publicités vidéo (certaines peuvent être bloquées)
- **LeMonde.fr** - Publicités françaises

#### Sites de test spécialisés :
- **https://theuselessweb.com/** - Sites aléatoires avec pubs
- **https://www.lemonde.fr/** - Site d'actualité avec pubs

### 4. **Vérification par comparaison**

1. **Désactivez le bloqueur** (cliquez sur l'icône shield)
2. Visitez un site avec des pubs (ex: Forbes.com)
3. **Notez** le nombre de bannières/publicités visibles
4. **Réactivez le bloqueur**
5. **Rechargez la page** (F5)
6. **Comparez** : vous devriez voir moins ou aucune pub

### 5. **Vérification dans le code source**

1. Ouvrez les **DevTools** (F12)
2. Allez dans l'onglet **Console**
3. Tapez :
   ```javascript
   window._notilusAdBlockerInstalled
   ```
4. Devrait retourner : `true` ✅

### 6. **Vérification des requêtes bloquées**

1. Ouvrez les **DevTools** (F12)
2. Allez dans l'onglet **Network** (Réseau)
3. Rechargez la page (F5)
4. Cherchez les requêtes avec statut **failed** ou **blocked**
5. Les URLs contenant :
   - `doubleclick`
   - `googlesyndication`
   - `googleadservices`
   - `ads`
   - `advertising`
   
   Devraient être **bloquées** ✅

### 7. **Indicateurs visuels**

#### ✅ Bloqueur ACTIVÉ :
- Icône shield **pleine** (shield_fill)
- Bordure **rouge** visible
- Fond légèrement coloré
- Tooltip affiche le compteur

#### ❌ Bloqueur DÉSACTIVÉ :
- Icône shield **vide** (shield)
- Pas de bordure
- Fond transparent
- Tooltip indique "désactivé"

### 8. **Test rapide en 30 secondes**

1. Ouvrez **https://www.forbes.com** (ou un site avec pubs)
2. Vérifiez l'icône shield dans la barre d'adresse (doit être activée)
3. Ouvrez la console (F12)
4. Rechargez la page (F5)
5. Regardez les messages `[Notilus AdBlocker] 🛡️ Bloqué`
6. Vérifiez visuellement : moins de bannières publicitaires

### 9. **Dépannage**

#### Le bloqueur ne semble pas fonctionner ?

1. ✅ Vérifiez que l'icône shield a une **bordure rouge** (activé)
2. ✅ Vérifiez la console pour les messages `[Notilus AdBlocker]`
3. ✅ Rechargez la page après activation
4. ✅ Vérifiez que vous n'êtes pas en mode navigation privée (si applicable)
5. ✅ Vérifiez les DevTools Network pour voir les requêtes bloquées

#### Le compteur ne s'incrémente pas ?

- Le compteur s'incrémente uniquement quand des pubs sont **détectées et bloquées**
- Sur certains sites sans pubs, le compteur restera à 0
- Testez sur un site avec beaucoup de publicités (Forbes, CNN, etc.)

### 10. **Domaines bloqués par défaut**

Le bloqueur bloque automatiquement :
- `doubleclick.net`
- `googleadservices.com`
- `googlesyndication.com`
- `google-analytics.com`
- `facebook.com/tr`
- `facebook.net`
- `amazon-adsystem.com`
- `advertising.com`
- `adnxs.com`
- `criteo.com`
- Et bien d'autres...

---

## 🎯 Résultat attendu

Quand le bloqueur fonctionne correctement :
- ✅ Moins de publicités visibles sur les sites
- ✅ Pages chargent plus vite
- ✅ Moins de données consommées
- ✅ Console affiche les blocages
- ✅ Compteur s'incrémente dans le tooltip

**Bon test ! 🚀**

