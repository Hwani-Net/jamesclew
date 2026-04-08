#!/bin/bash
# evaluator.sh — Generator와 완전히 분리된 Evaluator
# 용도: Playwright로 사용자 상호작용 흉내 + 외부 모델이 design_rubric.md로 등급 평가
# 출처: Anthropic Harness Ablation 연구 (Tech Bridge 2026-04-05)

set -e

URL="${1:-}"
if [ -z "$URL" ]; then
  echo "Usage: evaluator.sh <URL>"
  echo "Example: evaluator.sh https://example.web.app/"
  exit 1
fi

STATE_DIR="$HOME/.harness-state"
RUBRIC_FILE="D:/jamesclew/harness/rules/design_rubric.md"
SHOT_DIR="$STATE_DIR/evaluator_shots"
RESULT="$STATE_DIR/evaluator_result.json"

mkdir -p "$SHOT_DIR"

echo "🔍 Evaluator 시작: $URL"

# ─────────────────────────────────────
# Phase 1: Playwright로 사용자 상호작용 흉내
# ─────────────────────────────────────
echo "📸 Playwright 스크린샷 (데스크톱+모바일)..."

cat > "$SHOT_DIR/capture.mjs" <<'EOF'
import { chromium } from 'playwright';

const url = process.argv[2];
const outDir = process.argv[3];

const browser = await chromium.launch();

// 데스크톱
const ctxDesktop = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const pageD = await ctxDesktop.newPage();
await pageD.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
await pageD.screenshot({ path: `${outDir}/desktop.png`, fullPage: true });

// 모바일
const ctxMobile = await browser.newContext({
  viewport: { width: 390, height: 844 },
  deviceScaleFactor: 2,
  isMobile: true,
});
const pageM = await ctxMobile.newPage();
await pageM.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
await pageM.screenshot({ path: `${outDir}/mobile.png`, fullPage: true });

// 사용자 상호작용 시뮬레이션 — 모든 버튼/링크 수집
const interactive = await pageD.evaluate(() => {
  const els = [...document.querySelectorAll('button, a[href]')];
  return els.map(el => ({
    tag: el.tagName,
    text: (el.innerText || '').slice(0, 40),
    href: el.getAttribute('href') || null,
    visible: el.offsetParent !== null,
  })).slice(0, 30);
});

console.log(JSON.stringify({ interactive }, null, 2));

await browser.close();
EOF

cd "$SHOT_DIR"
node capture.mjs "$URL" "$SHOT_DIR" > "$SHOT_DIR/interactive.json" 2>&1 || {
  echo "❌ Playwright 캡처 실패"
  cat "$SHOT_DIR/interactive.json"
  exit 2
}

echo "✅ 스크린샷: $SHOT_DIR/desktop.png, mobile.png"
echo "✅ 인터랙션: $(cat "$SHOT_DIR/interactive.json" | head -1)"

# ─────────────────────────────────────
# Phase 2: 외부 모델 등급 평가 (Generator와 분리)
# ─────────────────────────────────────
echo "🤖 외부 모델 등급 평가 (Codex)..."

if [ ! -f "$RUBRIC_FILE" ]; then
  echo "❌ design_rubric.md 없음: $RUBRIC_FILE"
  exit 3
fi

RUBRIC=$(cat "$RUBRIC_FILE")
INTERACTIVE=$(cat "$SHOT_DIR/interactive.json")

PROMPT="다음 Anthropic Design Rubric으로 웹 앱을 평가하라.

=== RUBRIC ===
$RUBRIC

=== 평가 대상 ===
URL: $URL
데스크톱 스크린샷: $SHOT_DIR/desktop.png
모바일 스크린샷: $SHOT_DIR/mobile.png
인터랙티브 요소: $INTERACTIVE

=== 출력 형식 (JSON only) ===
{
  \"consistency\": {\"score\": 0-10, \"reason\": \"...\"},
  \"originality\": {\"score\": 0-10, \"reason\": \"...\", \"ai_cliches\": []},
  \"polish\": {\"score\": 0-10, \"reason\": \"...\"},
  \"functionality\": {\"score\": 0-10, \"reason\": \"...\"},
  \"lowest_axis\": \"originality|consistency|polish|functionality\",
  \"lowest_score\": 0-10,
  \"verdict\": \"PASS|REWORK|FAIL\",
  \"fixes\": [\"구체적 수정 1\", \"수정 2\"]
}

통과: 4개 축 모두 8점 이상. 5점 이하 있으면 FAIL."

codex exec "$PROMPT" 2>&1 | tee "$RESULT"

# ─────────────────────────────────────
# Phase 3: 판정 추출
# ─────────────────────────────────────
VERDICT=$(grep -oP '"verdict":\s*"\K[^"]+' "$RESULT" | head -1)
LOWEST=$(grep -oP '"lowest_score":\s*\K[0-9]+' "$RESULT" | head -1)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Evaluator 판정: $VERDICT (최저축: ${LOWEST}/10)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "결과 파일: $RESULT"
echo "스크린샷: $SHOT_DIR/"

if [ "$VERDICT" = "PASS" ]; then
  exit 0
elif [ "$VERDICT" = "REWORK" ]; then
  exit 1
else
  exit 2
fi
