#!/usr/bin/env bash
# blog-publish.sh — draft.md → MultiBlog/public/{slug}/index.html + firebase deploy
# Usage: bash harness/scripts/blog-publish.sh MultiBlog/drafts/{slug}/
set -euo pipefail

SITE_URL="${SITE_URL:-https://multi-blog-personal.web.app}"
SITE_NAME="${SITE_NAME:-스마트리뷰}"

DRAFT_DIR="${1:-}"
if [[ -z "$DRAFT_DIR" ]]; then
  echo "Usage: $0 <draft-dir>" >&2; exit 1
fi
DRAFT_DIR="${DRAFT_DIR%/}"  # strip trailing slash

DRAFT_MD="$DRAFT_DIR/draft.md"
META_JSON="$DRAFT_DIR/meta.json"
SLUG=$(basename "$DRAFT_DIR")
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# Derive public dir from draft location: drafts/../public or fallback to $REPO_ROOT/public
DRAFTS_PARENT="$(cd "$(dirname "$DRAFT_DIR")" && pwd)"
if [[ -d "$DRAFTS_PARENT/../public" ]]; then
  PUBLIC_ROOT="$(cd "$DRAFTS_PARENT/.." && pwd)/public"
else
  PUBLIC_ROOT="$REPO_ROOT/public"
fi
OUT_DIR="$PUBLIC_ROOT/$SLUG"

[[ -f "$DRAFT_MD" ]] || { echo "ERROR: $DRAFT_MD not found" >&2; exit 1; }

# --- 1. Install marked if missing ---
if ! command -v marked &>/dev/null; then
  echo "[publish] Installing marked globally..."
  npm install -g marked --quiet
fi

# --- 2. Parse frontmatter (YAML between --- markers) ---
TITLE=$(awk '/^---/{f++; next} f==1 && /^title:/{sub(/^title:[[:space:]]*/,""); gsub(/^"|"$/,""); print; exit}' "$DRAFT_MD")
DESC=$(awk '/^---/{f++; next} f==1 && /^description:/{sub(/^description:[[:space:]]*/,""); gsub(/^"|"$/,""); print; exit}' "$DRAFT_MD")
DATE=$(awk '/^---/{f++; next} f==1 && /^date:/{sub(/^date:[[:space:]]*/,""); print; exit}' "$DRAFT_MD")
KEYWORDS=$(awk '/^---/{f++; next} f==1 && /^keywords:/{sub(/^keywords:[[:space:]]*/,""); gsub(/[\[\]"]/,""); print; exit}' "$DRAFT_MD")

# Override description from meta.json seo.meta_description if available
if [[ -f "$META_JSON" ]]; then
  META_DESC=$(node -e "try{const m=require('$META_JSON');console.log(m.seo&&m.seo.meta_description||'')}catch(e){}" 2>/dev/null || true)
  [[ -n "$META_DESC" ]] && DESC="$META_DESC"
fi

TITLE="${TITLE:-스마트리뷰}"
DESC="${DESC:-}"
DATE="${DATE:-$(date +%Y-%m-%d)}"
KEYWORDS="${KEYWORDS:-}"

# --- 3. Strip frontmatter, replace [IMAGE:*] and [INTERNAL_LINK:*] ---
BODY_MD=$(awk '/^---/{f++; next} f>=2{print}' "$DRAFT_MD" \
  | sed -E 's/\[IMAGE:([^]]+)\]/<figure class="post-image"><img src="\/images\/\1.webp" alt="\1" width="800" height="600" onerror="this.style.display='\''none'\''"><\/figure>/g' \
  | sed -E 's/\[INTERNAL_LINK:([^]]+)\]/<a href="#" class="internal-link" data-topic="\1">\1<\/a>/g')

# --- 4. Convert markdown → HTML (node direct, marked CLI broken on Windows) ---
CONTENT=$(printf '%s\n' "$BODY_MD" | node -e "
const path=require('path');
const mp=path.join(process.env.APPDATA||'','npm/node_modules/marked');
const {marked}=require(mp);
let d='';process.stdin.on('data',c=>d+=c);
process.stdin.on('end',()=>process.stdout.write(marked(d)));
")

# --- 5. Inject into template ---
mkdir -p "$OUT_DIR"

cat > "$OUT_DIR/index.html" <<HTMLEOF
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${TITLE} | ${SITE_NAME}</title>
  <meta name="description" content="${DESC}">
  <meta name="keywords" content="${KEYWORDS}">
  <meta property="og:type" content="article">
  <meta property="og:title" content="${TITLE}">
  <meta property="og:description" content="${DESC}">
  <meta property="og:url" content="${SITE_URL}/${SLUG}/">
  <meta property="og:site_name" content="${SITE_NAME}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${TITLE}">
  <meta name="twitter:description" content="${DESC}">
  <meta property="article:published_time" content="${DATE}">
  <link rel="canonical" href="${SITE_URL}/${SLUG}/">
  <style>body{max-width:800px;margin:0 auto;padding:1rem 1.5rem;font-family:-apple-system,BlinkMacSystemFont,'Noto Sans KR',sans-serif;line-height:1.7;color:#1a1a1a}h1{font-size:1.8rem;line-height:1.3}h2{font-size:1.4rem;margin-top:2.5rem;border-bottom:2px solid #eee;padding-bottom:0.3rem}h3{font-size:1.15rem;margin-top:1.8rem}figure.post-image{margin:1.5rem 0;text-align:center}figure.post-image img{max-width:100%;height:auto;border-radius:8px}a{color:#0055cc}a.internal-link{color:#0077aa;text-decoration:underline dotted}.post-meta{color:#666;font-size:0.875rem;margin-bottom:2rem}</style>
</head>
<body>
  <header><nav><a href="${SITE_URL}/">← ${SITE_NAME} 홈</a></nav></header>
  <main>
    <article>
      <p class="post-meta">${DATE} | ${SITE_NAME}</p>
      ${CONTENT}
    </article>
  </main>
  <footer>
    <p style="color:#888;font-size:0.8rem;margin-top:3rem;border-top:1px solid #eee;padding-top:1rem">
      © ${SITE_NAME} — 본 콘텐츠는 쿠팡파트너스 활동의 일환으로 수수료를 받을 수 있습니다.
    </p>
  </footer>
</body>
</html>
HTMLEOF

echo "[publish] HTML → $OUT_DIR/index.html"

# --- 6. Write publish meta ---
cat > "$OUT_DIR/meta.json" <<METAEOF
{"slug":"${SLUG}","title":"${TITLE}","description":"${DESC}","publishedAt":"${DATE}","url":"${SITE_URL}/${SLUG}/"}
METAEOF

# --- 7. Update draft status.json ---
if [[ -f "$DRAFT_DIR/status.json" ]]; then
  node -e "
    const fs=require('fs');
    const p='$DRAFT_DIR/status.json';
    const s=JSON.parse(fs.readFileSync(p));
    s.status='published'; s.publishedAt='$(date -u +%Y-%m-%dT%H:%M:%SZ)';
    s.url='${SITE_URL}/${SLUG}/';
    fs.writeFileSync(p,JSON.stringify(s,null,2));
  " 2>/dev/null || true
fi

# --- 8. Firebase deploy if firebase.json exists ---
# Look for firebase.json: next to public dir, or repo root
FIREBASE_JSON="$(dirname "$PUBLIC_ROOT")/firebase.json"
[[ -f "$FIREBASE_JSON" ]] || FIREBASE_JSON="$REPO_ROOT/firebase.json"

if [[ -f "$FIREBASE_JSON" ]]; then
  echo "[publish] firebase.json found — deploying..."
  cd "$(dirname "$FIREBASE_JSON")"
  firebase deploy --only hosting 2>&1 | grep -E "(Deploy complete|Error|hosting)" || true
  echo "[publish] Deploy done. URL: ${SITE_URL}/${SLUG}/"
else
  echo "[publish] No firebase.json found — skipping deploy."
  echo "[publish] Manual deploy: cd $(dirname "$PUBLIC_ROOT") && firebase deploy --only hosting"
fi
