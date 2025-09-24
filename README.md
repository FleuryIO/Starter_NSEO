# 🌍 NSEO_starter

Un **starter technique**, un **voyage intérieur**, et un **espace de disciplines d’excellence**.  
Ce projet fournit une base solide pour NSEO : React + Vite + TailwindCSS, initialisé automatiquement via un script `bootstrap.sh`.

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
```

---

## 🔍 Développement du script

### Analyse statique avec shellcheck
Avant de modifier `bootstrap.sh`, valide-le avec [shellcheck](https://www.shellcheck.net/) :

```bash
# macOS
brew install shellcheck

# Debian/Ubuntu
sudo apt-get install -y shellcheck

# Analyse
shellcheck -x bootstrap.sh
```

### Scripts complémentaires (optionnels)
Pour ajouter linting et tests à ton projet, installe les dépendances puis ajoute ces scripts à `package.json` :

```bash
# ESLint
npm i -D eslint @eslint/js

# Vitest
npm i -D vitest
```

```json
{
  "scripts": {
    "lint": "eslint .",
    "test": "vitest"
  }
}
```

