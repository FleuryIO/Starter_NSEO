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
  npm create vite@latest . -- --template react -y
else
  # Vérifier que c'est bien un projet Vite React (présence de vite dans deps/scripts)
  if ! grep -q '"vite"' package.json; then
    warn "package.json trouvé mais 'vite' non détecté. Le dossier semble contenir un autre projet."
    warn "→ Soit change de dossier, soit supprime/backup l’existant avant de relancer."
  else
    ok "package.json déjà présent — projet Vite détecté, skip init."
  fi
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

# ─────────── log des versions clés ───────────
node <<'NODE' || warn "Impossible d'afficher les versions installées."
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json","utf8"));
const all = {...(pkg.dependencies||{}), ...(pkg.devDependencies||{})};
const pick = n => all[n] || "n/a";
console.log(`ℹ️  Versions → vite: ${pick("vite")} | react: ${pick("react")} | tailwindcss: ${pick("tailwindcss")} | @tailwindcss/postcss: ${pick("@tailwindcss/postcss")}`);
NODE

# ───── Tailwind v4 + PostCSS + Autoprefixer ────────
log "🎨 Vérif Tailwind v4 + PostCSS + Autoprefixer…"
npm i -D tailwindcss @tailwindcss/postcss postcss autoprefixer
ok "Packages Tailwind/PostCSS présents."

# ─── tailwind init (best-effort, non bloquant) ─────
TAILWIND_BIN="./node_modules/.bin/tailwindcss"
if [ ! -f tailwind.config.js ]; then
  log "🛠  Tentative de génération tailwind.config.js / postcss.config.js…"

  success=0
  if [ -x "$TAILWIND_BIN" ]; then
    if "$TAILWIND_BIN" init -p >/dev/null 2>&1; then
      success=1; ok "tailwindcss init via binaire local."
    fi
  fi
  if [ "$success" -eq 0 ]; then
    if npm exec -- tailwindcss init -p >/dev/null 2>&1; then
      success=1; ok "tailwindcss init via npm exec."
    fi
  fi
  if [ "$success" -eq 0 ]; then
    if npx -y tailwindcss@latest init -p >/dev/null 2>&1; then
      success=1; ok "tailwindcss init via npx (latest)."
    fi
  fi
  [ "$success" -eq 0 ] && warn "Impossible de lancer 'tailwindcss init' — je poursuis (les fichiers seront écrits manuellement)."
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
command -v git >/dev/null && [ ! -d .git ] && git init -q && git add . && git commit -m "chore: initial bootstrap" -q || true

