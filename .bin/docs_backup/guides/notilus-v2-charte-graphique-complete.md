# Notilus V2 - Charte Graphique Complete (Stack Web Moderne)

Version: `2.0.0`  
Date: `2026-03-03`  
Statut: `Reference officielle design V2`

---

## 0) Documents complementaires V2

Pour la definition complete de la structure ecran (pages, vues, panneaux, popups, modales), consulter:

- `.bin/docs_backup/guides/notilus-v2-interfaces-vues-complete.md`

Ce document (charte graphique) reste la reference visuelle, et le document interfaces reste la reference de cartographie des vues.

---

## 1) Vision de marque

Notilus est un produit "dev-first" a identite futuriste:

- Precision technique
- Energie neon controlee (pas "arcade noisy")
- Lisibilite maximale pour usage intensif
- Interface sombre, contraste net, feedbacks rapides

### 1.1 Principes visuels

1. **Clair avant decoratif**: l'information doit toujours passer avant les effets.
2. **Neon avec retenue**: la couleur d'accent sert a l'action, pas au remplissage massif.
3. **Profondeur utile**: blur/ombre uniquement pour separer les plans.
4. **Motion informative**: animation = signal d'etat, jamais pure decoration.
5. **Densite maitrisee**: interface compacte mais jamais etouffante.

---

## 2) ADN visuel Notilus

### 2.1 Couleurs coeur (source actuelle)

| Token | Hex | Usage |
|---|---|---|
| `notilus-neon-red` | `#FF2D55` | Accent principal par defaut |
| `notilus-neon-red-dark` | `#B1165A` | Hover/pressed accent |
| `chrome` | `#101018` | Surface technique |
| `chrome-dark` | `#0B0B11` | Fond profond |
| `chrome-light` | `#181824` | Surface elevee |
| `tooltip-bg` | `#1C1C28` | Tooltip/popup |
| `native-bg` | `#09080D` | Fond global natif |

### 2.2 Palettes alternatives officielles (accent dynamique)

| Theme ID | Nom | Primary | Primary Dark |
|---|---|---|---|
| `red` | Rouge Notilus | `#FF2D55` | `#B1165A` |
| `blue` | Bleu Cyber | `#007AFF` | `#0051D5` |
| `green` | Vert Matrix | `#34C759` | `#248A3D` |
| `purple` | Violet Neon | `#5856D6` | `#3D3BA8` |
| `orange` | Orange Fire | `#FF9500` | `#CC7700` |
| `pink` | Rose Cyber | `#FF2D92` | `#CC2474` |

### 2.3 Themes historiques (compatibilite / migration)

| Theme | Primary | Secondary | Background | Surface |
|---|---|---|---|---|
| Dark Red | `#FF0040` | `#FF3366` | `#0D0D0D` | `#1A1A1A` |
| Dark Blue | `#00D4FF` | `#0099CC` | `#0A0E27` | `#151B3D` |
| Cyberpunk | `#FF00FF` | `#00FFFF` | `#000000` | `#1A0033` |
| Matrix | `#00FF00` | `#00CC00` | `#000000` | `#0A0A0A` |
| Dracula | `#FF5555` | `#BD93F9` | `#282A36` | `#343746` |

---

## 3) Logo et identite

### 3.1 Construction logo (N circulaire)

- Anneau externe: `#FF0040`
- Fond radial interne: `#1A0A1A -> #0D050D`
- Barre gauche: gradient `#FF3366 -> #FF0040`
- Diagonale: `#FF3366 -> #FF6699 -> #E0E0E0`
- Barre droite: `#C0C0C0 -> #E0E0E0`

### 3.2 Regles d'usage

- Fond recommande: sombre (`#09080D` a `#1C1C28`)
- Zone de protection minimale: `0.25x` (x = diametre du logo)
- Taille minimale:
  - UI dense: `24px`
  - UI standard: `32px`
  - Hero/branding: `>=96px`
- Ne pas:
  - ecraser horizontalement/verticalement
  - changer les couleurs du logo sans variante officielle
  - ajouter contour externe non specifie

### 3.3 Fichiers officiels

- `assets/notilus-logo.png` (source raster)
- `assets/notilus-logo.ico` (Windows/app icon)

---

## 4) Systeme de tokens V2 (web)

### 4.1 Couleurs semantiques

| Token | Valeur | Usage |
|---|---|---|
| `--color-bg` | `#09080D` | Fond app |
| `--color-surface-1` | `#101018` | Surface primaire |
| `--color-surface-2` | `#181824` | Surface secondaire |
| `--color-surface-3` | `#1C1C28` | Popover / tooltip |
| `--color-border` | `rgba(255,255,255,0.12)` | Bordures |
| `--color-border-strong` | `rgba(255,255,255,0.24)` | Focus visible |
| `--color-text-primary` | `#E7E7EC` | Texte principal |
| `--color-text-secondary` | `#A8A8B3` | Texte secondaire |
| `--color-text-muted` | `#7D7D89` | Placeholder/meta |
| `--color-accent` | `#FF2D55` | CTA/action |
| `--color-accent-hover` | `#B1165A` | Hover action |
| `--color-success` | `#34C759` | Etat succes |
| `--color-warning` | `#FF9500` | Etat warning |
| `--color-error` | `#FF3B30` | Etat erreur |
| `--color-info` | `#007AFF` | Etat info |

### 4.2 Opacites standard

| Token | Valeur |
|---|---|
| `--alpha-disabled` | `0.38` |
| `--alpha-muted` | `0.56` |
| `--alpha-subtle` | `0.72` |
| `--alpha-strong` | `0.92` |

### 4.3 Gradients officiels

```css
--gradient-brand-1: linear-gradient(135deg, #ff2d55 0%, #b1165a 100%);
--gradient-brand-2: linear-gradient(135deg, #ff3366 0%, #ff0040 50%, #b1165a 100%);
--gradient-surface: linear-gradient(180deg, #181824 0%, #101018 100%);
--gradient-overlay: radial-gradient(120% 120% at 50% 0%, rgba(255,45,85,0.12) 0%, rgba(255,45,85,0) 60%);
```

### 4.4 Glow / shadow

```css
--shadow-sm: 0 2px 4px rgba(0,0,0,0.25);
--shadow-md: 0 6px 16px rgba(0,0,0,0.35);
--shadow-lg: 0 12px 32px rgba(0,0,0,0.45);
--glow-accent-sm: 0 0 10px rgba(255,45,85,0.35);
--glow-accent-md: 0 0 18px rgba(255,45,85,0.45);
--glow-accent-lg: 0 0 28px rgba(255,45,85,0.55);
```

---

## 5) Typographie

### 5.1 Families

- `Orbitron`: titres, labels techno, KPI
- `Rajdhani`: texte principal, UI dense, forms

Fallback web recommande:

```css
--font-display: "Orbitron", "Segoe UI", "Inter", sans-serif;
--font-body: "Rajdhani", "Segoe UI", "Inter", sans-serif;
```

### 5.2 Echelle type V2

| Role | Font | Size | Weight | Line-height | Tracking |
|---|---|---:|---:|---:|---:|
| Display L | Orbitron | 34 | 700 | 1.15 | 0.2px |
| Display M | Orbitron | 28 | 600 | 1.2 | 0.2px |
| H1 | Orbitron | 22 | 600 | 1.25 | 0.15px |
| H2 | Orbitron | 18 | 600 | 1.3 | 0.1px |
| Body L | Rajdhani | 17 | 400 | 1.45 | 0 |
| Body M | Rajdhani | 15 | 400 | 1.45 | 0 |
| Label | Rajdhani | 13 | 600 | 1.35 | 0.1px |
| Caption | Rajdhani | 12 | 400 | 1.35 | 0 |
| Code | Rajdhani | 13 | 400 | 1.4 | 0 |

### 5.3 Regles

- Ne jamais utiliser plus de 2 familles simultanees.
- Titres en Orbitron reserves aux points de hierarchie.
- Texte long en Rajdhani uniquement.
- Eviter `font-weight` < 400 pour lisibilite sur fond sombre.

---

## 6) Espacement, grille, dimensions

### 6.1 Spacing scale

| Token | px |
|---|---:|
| `--space-1` | 4 |
| `--space-2` | 8 |
| `--space-3` | 12 |
| `--space-4` | 16 |
| `--space-5` | 24 |
| `--space-6` | 32 |
| `--space-7` | 48 |

### 6.2 Radius

| Token | px |
|---|---:|
| `--radius-sm` | 4 |
| `--radius-md` | 8 |
| `--radius-lg` | 12 |
| `--radius-xl` | 16 |
| `--radius-pill` | 999 |

### 6.3 Breakpoints web

| Nom | Min | Max |
|---|---:|---:|
| `xs` | 0 | 479 |
| `sm` | 480 | 767 |
| `md` | 768 | 1023 |
| `lg` | 1024 | 1439 |
| `xl` | 1440 | 1919 |
| `2xl` | 1920 | - |

### 6.4 Grille

- Desktop: 12 colonnes
- Tablet: 8 colonnes
- Mobile: 4 colonnes
- Gutter: `16px` (mobile), `24px` (desktop)
- Max content width recommande: `1440px`

---

## 7) Motion system

### 7.1 Durees officielles

| Token | Valeur |
|---|---|
| `--motion-fast` | `150ms` |
| `--motion-normal` | `250ms` |
| `--motion-panel` | `350ms` |
| `--motion-slow` | `400ms` |

### 7.2 Courbes officielles

| Token | Courbe |
|---|---|
| `--ease-default` | `cubic-bezier(0.215, 0.61, 0.355, 1)` |
| `--ease-smooth` | `cubic-bezier(0.645, 0.045, 0.355, 1)` |
| `--ease-sharp` | `cubic-bezier(0.19, 1, 0.22, 1)` |

### 7.3 Interactions standards

- Hover scale: `1.03` a `1.05`
- Press scale: `0.95` a `0.97`
- Fade-in entrance: `opacity 0 -> 1` + `translateY(10px -> 0)`
- Panels: slide + fade simultane

---

## 8) Composants UI (spec V2)

### 8.1 Button

- Hauteurs: `32 / 40 / 48`
- Radius: `8` (default), `12` (hero)
- Primary:
  - bg: `--color-accent`
  - hover: `--color-accent-hover`
  - text: `#FFFFFF`
  - shadow: `--glow-accent-sm`
- Secondary:
  - bg: `rgba(255,255,255,0.04)`
  - border: `--color-border`
  - hover bg: `rgba(255,255,255,0.08)`

### 8.2 Input / Search

- Height: `40` (dense) / `48` (default)
- Background: `--color-surface-1`
- Border: `1px solid --color-border`
- Focus ring: `2px solid rgba(255,45,85,0.5)`
- Placeholder: `--color-text-muted`

### 8.3 Card / Panel

- Background: `--color-surface-1` ou gradient surface
- Border radius: `12`
- Border: `1px solid --color-border`
- Shadow: `--shadow-md`
- Optional glass: `backdrop-filter: blur(10px)`

### 8.4 Tabs

- Inactive text: `--color-text-secondary`
- Active text: `--color-text-primary`
- Active indicator: `2px --color-accent`
- Hover bg: `rgba(255,255,255,0.06)`

### 8.5 Notifications

- Container: `--color-surface-3`, radius `12`, border `--color-border`
- Error icon/accent: `--color-error`
- Warning icon/accent: `--color-warning`
- Success icon/accent: `--color-success`

### 8.6 Tooltip

- Fond: `#1C1C28`
- Texte: `#E7E7EC`
- Radius: `8`
- Delay apparition: `500ms`

---

## 9) Accessibilite (non negociable)

1. Contraste minimum:
   - Texte normal: `4.5:1`
   - Texte large: `3:1`
2. Focus visible clavier sur tous les elements interactifs.
3. Taille cible clic:
   - min `40x40` (desktop)
   - min `44x44` (touch)
4. Etats explicites (hover/focus/active/disabled/loading).
5. `prefers-reduced-motion`:
   - couper shimmer/pulse
   - reduire durees a `<=100ms`

Snippet:

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition-duration: 80ms !important;
    scroll-behavior: auto !important;
  }
}
```

---

## 10) Implementation web moderne

### 10.1 CSS variables (base)

```css
:root {
  --color-bg: #09080d;
  --color-surface-1: #101018;
  --color-surface-2: #181824;
  --color-surface-3: #1c1c28;
  --color-border: rgba(255,255,255,0.12);
  --color-border-strong: rgba(255,255,255,0.24);
  --color-text-primary: #e7e7ec;
  --color-text-secondary: #a8a8b3;
  --color-text-muted: #7d7d89;
  --color-accent: #ff2d55;
  --color-accent-hover: #b1165a;
  --color-success: #34c759;
  --color-warning: #ff9500;
  --color-error: #ff3b30;
  --color-info: #007aff;

  --font-display: "Orbitron", "Segoe UI", "Inter", sans-serif;
  --font-body: "Rajdhani", "Segoe UI", "Inter", sans-serif;

  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 24px;
  --space-6: 32px;
  --space-7: 48px;

  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-pill: 999px;

  --motion-fast: 150ms;
  --motion-normal: 250ms;
  --motion-panel: 350ms;
  --motion-slow: 400ms;
}
```

### 10.2 Tailwind (suggestion V2)

```js
// tailwind.config.js
export default {
  theme: {
    extend: {
      colors: {
        notilus: {
          bg: "#09080d",
          surface1: "#101018",
          surface2: "#181824",
          surface3: "#1c1c28",
          accent: "#ff2d55",
          accentDark: "#b1165a",
          text: "#e7e7ec",
          muted: "#a8a8b3",
          success: "#34c759",
          warning: "#ff9500",
          error: "#ff3b30"
        }
      },
      fontFamily: {
        display: ["Orbitron", "Segoe UI", "Inter", "sans-serif"],
        body: ["Rajdhani", "Segoe UI", "Inter", "sans-serif"]
      },
      borderRadius: {
        sm: "4px",
        md: "8px",
        lg: "12px",
        xl: "16px"
      },
      transitionDuration: {
        fast: "150ms",
        normal: "250ms",
        panel: "350ms",
        slow: "400ms"
      }
    }
  }
}
```

### 10.3 JSON tokens (design -> code)

```json
{
  "color": {
    "accent": "#FF2D55",
    "accentHover": "#B1165A",
    "bg": "#09080D",
    "surface1": "#101018",
    "surface2": "#181824",
    "textPrimary": "#E7E7EC",
    "textSecondary": "#A8A8B3"
  },
  "typography": {
    "fontDisplay": "Orbitron",
    "fontBody": "Rajdhani",
    "scale": [12, 13, 15, 17, 18, 22, 28, 34]
  },
  "radius": { "sm": 4, "md": 8, "lg": 12, "xl": 16 },
  "motion": { "fast": 150, "normal": 250, "panel": 350, "slow": 400 }
}
```

---

## 11) Regles de coherence V2

1. Une seule couleur accent dominante par ecran (theme actif).
2. Maximum 2 niveaux de glow visibles en meme temps.
3. Ne pas empiler `box-shadow` + `backdrop-blur` + gradient fort sur le meme petit composant.
4. Toute action critique doit avoir:
   - etat normal
   - hover
   - focus
   - pressed
   - disabled
   - loading
5. Tous les composants partagent la meme echelle spacing/radius/motion.

---

## 12) Checklist QA visuelle

### 12.1 Branding

- [ ] Logo net a 24/32/48/96 px
- [ ] Zone de protection respectee
- [ ] Accent conforme au theme actif

### 12.2 UI

- [ ] Contraste texte valide
- [ ] Focus clavier visible partout
- [ ] Etats interactifs complets
- [ ] Densite homogene entre pages

### 12.3 Motion

- [ ] Durees conformes tokens
- [ ] Pas d'animation "gratuite"
- [ ] Mode reduced-motion supporte

### 12.4 Responsive

- [ ] Layout stable a 360 / 768 / 1024 / 1440 / 1920
- [ ] Cibles tactiles >= 44px en mobile
- [ ] Typo lisible sans zoom

---

## 13) Decision pour V2 web

Pour la V2 en stack web moderne, la baseline recommandee est:

- Theme par defaut: `Rouge Notilus` (`#FF2D55`)
- Fond global: `#09080D`
- Surface principale: `#101018`
- Typo: `Orbitron + Rajdhani`
- Radius standard: `8/12`
- Motion standard: `150/250/350ms`

Cette baseline doit etre appliquee avant toute variation produit.
