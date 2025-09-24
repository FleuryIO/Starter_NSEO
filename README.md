# 🌍 Starter_NSEO

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build](https://github.com/FleuryIO/Starter_NSEO/actions/workflows/ci.yml/badge.svg)](https://github.com/FleuryIO/Starter_NSEO/actions)

Un **starter technique**, un **voyage intérieur**, et un **espace de disciplines d’excellence**.  
Ce projet fournit une base solide pour NSEO : **React 19 + Vite 7 + TailwindCSS v4**, initialisé automatiquement via un script `bootstrap.sh`.

---

## 🚀 Installation & lancement

### Pré-requis
- [Node.js](https://nodejs.org/) ≥ 18 (paramétrable via `MIN_NODE_MAJOR`)
- npm ≥ 9 (paramétrable via `MIN_NPM_MAJOR`)
- Pour bloquer strictement si en dessous : `STRICT_VERSIONS=1`

### Bootstrap automatique
Clone le dépôt puis lance le script :

```bash
## Start here (copier-coller)
chmod +x bootstrap.sh
./bootstrap.sh "$HOME/Documents/Projets/NSEO_starter" \
  && cd "$HOME/Documents/Projets/NSEO_starter" \
  && npm run dev
