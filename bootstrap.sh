#!/usr/bin/env bash
set -Eeuo pipefail

# ───────────────────── helpers ─────────────────────
ts()   { date +"%Y%m%d-%H%M%S"; }
log()  { printf "• %s\n" "$*"; }
ok()   { printf "✅ %s\n" "$*"; }
warn() { printf "⚠️  %s\n" "$*" >&2; }
die()  { printf "❌ %s\n" "$*" >&2; exit 1; }

trap 'die "Erreur à la ligne $LINENO."' ERR

# ───────────────── destination ─────────────────────
DEFAULT_DIR="${HOME}/Documents/Projets/NSEO_starter"
PROJECT_DIR="${1:-${PROJECT_DIR:-$DEFAULT_DIR}}"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

log "Dossier projet : $PROJECT_DIR"

# ──────────────── prérequis & versions ─────────────
command -v node >/dev/null 2>&1 || die "Node.js introuvable. Installe-le (ex: via nvm)."
command -v npm  >/dev/null 2>&1 || die "npm introuvable."

NODE_V="$(node -v | sed 's/^v//')"
NPM_V="$(npm -v)"
log "Node: $NODE_V  |  npm: $NPM_V"

major() { echo "$1" | cut -d. -f1; }

# Seuils paramétrables (override via env)
MIN_NODE_MAJOR="${MIN_NODE_MAJOR:-18}"
MIN_NPM_MAJOR="${MIN_NPM_MAJOR:-9}"
STRICT_VERSIONS="${STRICT_VERSIONS:-0}"

NODE_MAJOR="$(major "$NODE_V")"
NPM_MAJOR="$(major "$NPM_V")"

if [ "$NODE_MAJOR" -lt "$MIN_NODE_MAJOR" ]; then
  warn "Node <$MIN_NODE_MAJOR détecté (=$NODE_MAJOR)."
  [ "$STRICT_VERSIONS" = "1" ] && die "Versions strictes activées (STRICT_VERSIONS=1)."
fi
if [ "$NPM_MAJOR" -lt "$MIN_NPM_MAJOR" ]; then
  warn "npm <$MIN_NPM_MAJOR détecté (=$NPM_MAJOR)."
  [ "$STRICT_VERSIONS" = "1" ] && die "Versions strictes activées (STRICT_VERSIONS=1)."
fi

# ───────────── init Vite si nécessaire ─────────────
if [ ! -f package.json ]; then
  log "⚡ Init Vite + React…"
  npm create vite@latest . -- --template react
else
  ok "package.json déjà présent — skip init."
fi

# ─────────────────── install ───────────────────────
if [ -f package-lock.json ]; then
  log "📦 npm ci…"
  npm ci
else
  log "📦 npm install…"
  npm install
fi
ok "Dépendances installées."

# ───── Tailwind v4 + PostCSS + Autoprefixer ────────
# NOTE: Tailwind v4 requiert @tailwindcss/postcss comme plugin PostCSS
log "🎨 Vérif Tailwind v4 + PostCSS + Autoprefixer…"
npm i -D tailwindcss @tailwindcss/postcss postcss autoprefixer
ok "Packages Tailwind/PostCSS présents."

# ─── tailwind init (best-effort, non bloquant) ─────
TAILWIND_BIN="./node_modules/.bin/tailwindcss"
if [ ! -f tailwind.config.js ]; then
  log "🛠  Tentative de génération tailwind.config.js / postcss.config.js…"

  success=0

  # Méthode 1 : binaire local
  if [ -x "$TAILWIND_BIN" ]; then
    if "$TAILWIND_BIN" init -p >/dev/null 2>&1; then
      success=1
      ok "tailwindcss init via binaire local."
    fi
  fi

  # Méthode 2 : npm exec (npm 9/10+ ; note le --)
  if [ "$success" -eq 0 ]; then
    if npm exec -- tailwindcss init -p >/dev/null 2>&1; then
      success=1
      ok "tailwindcss init via npm exec."
    fi
  fi

  # Méthode 3 : npx (avec version explicite pour fiabilité)
  if [ "$success" -eq 0 ]; then
    if npx -y tailwindcss@latest init -p >/dev/null 2>&1; then
      success=1
      ok "tailwindcss init via npx (latest)."
    fi
  fi

  if [ "$success" -eq 0 ]; then
    warn "Impossible de lancer 'tailwindcss init' — je poursuis (les fichiers seront écrits manuellement)."
  fi
else
  ok "tailwind.config.js déjà présent — skip init."
fi

# ─ sauvegardes + (re)écriture configs propres ──────
backup_if_exists() {
  local f="$1"
  if [ -f "$f" ]; then
    local b="$f.bak-$(ts)"
    cp "$f" "$b"
    ok "Sauvegarde de $f → $b"
  fi
}

# tailwind.config.js (compatible v3/v4, optionnel en v4)
backup_if_exists "tailwind.config.js"
cat > tailwind.config.js <<'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx,ts,tsx}"],
  theme: { extend: {} },
  plugins: [],
};
EOF
ok "tailwind.config.js écrit."

# postcss.config.js → plugin v4 requis: @tailwindcss/postcss
backup_if_exists "postcss.config.js"
cat > postcss.config.js <<'EOF'
export default {
  plugins: {
    "@tailwindcss/postcss": {},
    autoprefixer: {},
  },
};
EOF
ok "postcss.config.js écrit (plugin @tailwindcss/postcss)."

# ──────────────── index.css (v4 style) ─────────────
# En v4, on recommande un import unique :
#   @import "tailwindcss";
# On sauvegarde l'ancien et on écrit une version propre.
CSS_FILE="src/index.css"
mkdir -p src
backup_if_exists "$CSS_FILE"
cat > "$CSS_FILE" <<'EOF'
@import "tailwindcss";
/* Place ici tes styles app si besoin */
EOF
ok "src/index.css écrit (style Tailwind v4)."

# ─────────── scripts package.json (Vite) ───────────
node <<'NODE' || die "Échec mise à jour scripts package.json."
const fs = require("fs");
const p = "package.json";
const pkg = JSON.parse(fs.readFileSync(p, "utf8"));
pkg.scripts = Object.assign(
  { dev: "vite", build: "vite build", preview: "vite preview" },
  pkg.scripts || {}
);
fs.writeFileSync(p, JSON.stringify(pkg, null, 2));
NODE
ok "Scripts npm (dev/build/preview) assurés."

echo
ok "Setup terminé."
echo "▶ Lance le serveur : npm run dev"
echo "   (Dossier : $PROJECT_DIR)"
