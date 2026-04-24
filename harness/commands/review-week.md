---
description: "주간 세컨드브레인 회고 — BASB Review 단계"
user_invocable: true
---

# /review-week — 주간 세컨드브레인 회고

## 사용법
- `/review-week` — 현재 주 기준 7일 회고 실행

## 실행 절차

### Step 1: gbrain 최근 페이지 수집
```bash
gbrain list -n 100
```
출력 중 `updated_at` 또는 `created_at` 기준 오늘로부터 7일 이내 항목만 필터링.
날짜 비교: `date -d "7 days ago" +%Y-%m-%d` 기준 이후 페이지만 대상.

### Step 2: type별 분류
필터링된 페이지를 slug 접두사 기준으로 분류:
- `pitfall-*` → **pitfall** (실수·교훈)
- `skill-*` → **skill** (재사용 절차)
- 외부 URL/링크 포함 → **source** (참조 문서)
- 그 외 → **concept** (개념·패턴)

분류 결과를 변수에 저장 (LLM 프롬프트 입력용).

### Step 3: Obsidian 06-raw/ inbox 스캔
```bash
VAULT="${OBSIDIAN_VAULT:-C:/Users/AIcreator/Obsidian-Vault}"
ls "$VAULT/06-raw/"*.md 2>/dev/null
```
- 파일 목록 수집 후 `05-wiki/` 에 동명 파일이 없는 것 = inbox 상태로 판별
- inbox 파일 목록을 LLM 프롬프트에 함께 포함

### Step 4: LLM 분석 (GPT-4.1 → Codex fallback)

**GPT-4.1 호출 (1순위)**:
```bash
PAYLOAD=$(cat <<EOF
{
  "model": "gpt-4.1",
  "messages": [{
    "role": "user",
    "content": "아래 주간 신규 지식 목록을 분석하라.\n\n[gbrain 신규 페이지]\n${GBRAIN_LIST}\n\n[Obsidian 06-raw inbox]\n${INBOX_LIST}\n\n다음 4가지를 JSON으로 출력하라:\n1. top_themes: 핵심 주제 3개 (배열)\n2. link_suggestions: 연결 제안 (이 페이지 slug ↔ 기존 페이지 slug, 이유 포함, 최대 5쌍)\n3. delete_candidates: 삭제 후보 slug + 이유 (중복·과잉 디테일, 최대 3개)\n4. next_research: 다음주 우선순위 리서치 키워드 3개 (배열)"
  }]
}
EOF
)
echo "$PAYLOAD" > /tmp/review-week-payload.json
RESULT=$(curl -s --max-time 30 http://localhost:4141/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d @/tmp/review-week-payload.json)
```

**Codex fallback (GPT-4.1 실패 또는 서버 미응답 시)**:
```bash
bash harness/scripts/codex-rotate.sh "주간 지식 목록: ${GBRAIN_LIST}\n\nInbox: ${INBOX_LIST}\n\n핵심주제 3개, 연결 제안 5쌍, 삭제후보 3개, 리서치키워드 3개를 JSON으로 출력"
```

### Step 5: 결과 Obsidian 저장
```bash
VAULT="${OBSIDIAN_VAULT:-C:/Users/AIcreator/Obsidian-Vault}"
YEAR=$(date +%Y)
WEEK=$(date +%V)
OUTPUT_FILE="$VAULT/01-jamesclaw/reviews/weekly-${YEAR}-W${WEEK}.md"

# 충돌 방지: 이미 존재하면 타임스탬프 접미사
if [ -f "$OUTPUT_FILE" ]; then
  SUFFIX=$(date +%Y%m%d%H%M)
  OUTPUT_FILE="$VAULT/01-jamesclaw/reviews/weekly-${YEAR}-W${WEEK}-${SUFFIX}.md"
fi

cat > "$OUTPUT_FILE" <<MDEOF
# 주간 회고 — ${YEAR} W${WEEK}

생성일: $(date +%Y-%m-%d)

## gbrain 신규 페이지 (7일 이내)
${GBRAIN_LIST}

## Obsidian inbox (미분류)
${INBOX_LIST}

## LLM 분석 결과
${LLM_RESULT}
MDEOF
```

### Step 6: gbrain 동기화
```bash
YEAR=$(date +%Y)
WEEK=$(date +%V)
gbrain put "weekly-review-${YEAR}-W${WEEK}" < "$OUTPUT_FILE"
```
실패 시 3회 재시도 후 스킵 (저장 파일은 유지).

### Step 7: 대표님 요약 출력
다음 형식으로 5줄 이내 출력:
```
[review-week 완료] YYYY W##
- 신규 gbrain 페이지: N건 (pitfall X / skill X / source X / concept X)
- inbox 미분류: N건
- 핵심 주제: {top_themes}
- 다음주 리서치: {next_research}
- 저장: {OUTPUT_FILE}
```

## 전제 조건
- gbrain CLI 설치 및 서버 실행 중 (`gbrain serve`)
- `$OBSIDIAN_VAULT/01-jamesclaw/reviews/` 디렉토리 존재
- GPT-4.1 (localhost:4141) 또는 Codex CLI 사용 가능

## 주의사항
- 기존 weekly 파일 덮어쓰기 금지 — 충돌 시 `-YYYYMMDDHHMM` 접미사 자동 부여
- LLM 결과가 JSON 파싱 실패 시 raw 텍스트 그대로 저장 (분석 생략 아님)
- `gbrain list` 날짜 필드명이 버전마다 다를 수 있음 — `updated_at` 없으면 `created_at` 사용
