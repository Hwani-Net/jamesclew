# /blog-fix — 품질 게이트 실패 시 자동 수정 + 에스컬레이션 루프

`/blog-review`에서 FAIL 판정된 초안을 최대 3회 자동 수정하고 재검증.
매회 다른 모델을 사용하여 같은 실수 반복 방지.
3회 모두 실패 시 텔레그램 에스컬레이션.

## 사용법
- `/blog-fix` — `status.json`이 `failed`인 최신 초안 자동 선택
- `/blog-fix MultiBlog/drafts/2026-04-11-keyword/` — 특정 초안 지정

## 산출물
- `MultiBlog/drafts/{slug}/draft.md` — 수정된 초안 (원본은 `draft.md.bak`으로 백업)
- `MultiBlog/drafts/{slug}/fix-log.json` — 수정 이력 (회차, 모델, 변경 내용, 재검증 결과)
- `MultiBlog/drafts/{slug}/status.json` — `ready` (수정 성공) 또는 `escalated` (3회 실패)

## 실행 절차

### Phase 0: 사전 준비

**0-1. 실패 항목 파악**
```
quality-report.json에서 FAIL 항목 추출:
- aiSmell.verdict === "FAIL" → AI냄새 수정 필요
- seo.verdict === "FAIL" → SEO 보강 필요
- images.verdict === "FAIL" → 이미지 교체 필요
- expectGates[].pass === false → 렌더링/성능 수정 필요
```

**0-2. 원본 백업**
```bash
cp "MultiBlog/drafts/{slug}/draft.md" "MultiBlog/drafts/{slug}/draft.md.bak"
```

**0-3. 수정 전략 결정 (Opus 판단)**
실패 유형별 수정 프롬프트를 미리 설계:
- AI냄새 FAIL → "AI 특유 표현을 자연스러운 구어체로 교체. 구체적 경험/수치 추가."
- SEO FAIL → "키워드 밀도 보강, FAQ 추가, 내부링크 삽입."
- 이미지 FAIL → "대체 이미지 검색 + 다운로드."
- 복합 FAIL → 우선순위: AI냄새 → SEO → 이미지 순으로 수정.

### Phase 1: 수정 루프 (최대 3회)

**라운드 1 — Sonnet 서브에이전트**
```
Agent(model: sonnet, prompt: "
다음 블로그 글의 품질 문제를 수정해라.

[실패 항목]: {failedGates 목록}
[수정 지시]: {Phase 0에서 설계한 수정 프롬프트}
[원본]: {draft.md 내용}

수정된 전체 마크다운을 출력하라. frontmatter 유지.")
```
- 수정 결과를 `draft.md`에 덮어쓰기
- `/blog-review` 재실행 (Phase 2~4만, expect MCP는 스킵 가능)
- PASS → 완료. FAIL → 라운드 2로.
- **regression 감지**: 이전 PASS 항목이 FAIL 전환 → 수정 롤백 (`draft.md.bak` 복원) → 라운드 2로.

**라운드 2 — Codex CLI**
```bash
codex exec "다음 블로그 글의 품질 문제를 수정하라.

실패 항목: {failedGates}
수정 지시: {수정 프롬프트}
라운드 1 수정이 실패한 이유: {라운드 1 재검증 실패 항목}

전체 수정된 마크다운 출력.

---
$(cat MultiBlog/drafts/{slug}/draft.md)"
```
- 결과를 `draft.md`에 저장 → `/blog-review` 재실행
- PASS → 완료. FAIL → 라운드 3로.
- regression 감지 → 롤백 → 라운드 3로.

**라운드 3 — GPT-4.1 (또는 Gemma 4 로컬)**
```bash
CONTENT=$(cat MultiBlog/drafts/{slug}/draft.md)
curl -s --max-time 30 http://localhost:4141/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"gpt-4.1\",\"messages\":[{\"role\":\"user\",\"content\":\"다음 블로그 글의 품질 문제를 수정하라.\\n\\n실패 항목: {failedGates}\\n수정 지시: {수정 프롬프트}\\n이전 2회 수정이 실패한 이유: {라운드 1,2 실패 분석}\\n이번이 마지막 시도이므로 가장 보수적으로 수정하라.\\n\\n전체 수정된 마크다운 출력.\\n\\n---\\n$CONTENT\"}]}" \
  | jq -r '.choices[0].message.content'
```
GPT-4.1 실패 시 (copilot-api 서버 다운 등) Gemma 4 로컬 폴백:
```bash
curl -s http://localhost:11434/api/generate -d '{
  "model": "gemma3:27b",
  "prompt": "...",
  "stream": false
}' | jq -r '.response'
```
- 결과를 `draft.md`에 저장 → `/blog-review` 재실행
- PASS → 완료. FAIL → 에스컬레이션.

### Phase 2: 에스컬레이션 (3회 실패 시)

**2-1. 에스컬레이션 메시지 구성**
```
🚨 품질 게이트 실패 — 자동 수정 3회 실패
📄 글: {title}
❌ 실패 항목: {최종 failedGates}
🔄 시도 이력:
  R1 (Sonnet): {결과 요약}
  R2 (Codex): {결과 요약}
  R3 (GPT-4.1): {결과 요약}
🤔 필요 판단: {Opus의 분석 — 왜 자동 수정이 안 되는지, 대표님이 뭘 결정해야 하는지}
📁 위치: MultiBlog/drafts/{slug}/
```

**2-2. 텔레그램 발송**
```
mcp__plugin_telegram_telegram__reply (chat_id, message)
```
텔레그램 MCP 사용 불가 시:
```bash
echo "에스컬레이션 내용" > ~/.harness-state/last_result.txt
```
Stop hook이 자동 전송.

**2-3. 상태 업데이트**
```json
// status.json
{ "status": "escalated", "escalatedAt": "...", "attempts": 3 }
```

### Phase 3: 수정 이력 기록

**fix-log.json 구조**:
```json
{
  "slug": "...",
  "originalFailedGates": ["aiSmell", "seo"],
  "rounds": [
    {
      "round": 1,
      "model": "sonnet",
      "fixApplied": "AI냄새 표현 12개 교체, FAQ 2개 추가",
      "reviewResult": "FAIL — aiSmell 35 (WARN→수정 불충분)",
      "regression": false,
      "duration": "45s"
    },
    { "round": 2, "model": "codex", ... },
    { "round": 3, "model": "gpt-4.1", ... }
  ],
  "finalStatus": "ready | escalated",
  "totalDuration": "4m 30s"
}
```

**하네스 증거 기록**:
```bash
echo "blog-fix: {slug} | rounds={n} | final={status} | $(date)" >> ~/.harness-state/last_result.txt
```

## 핵심 규칙
1. **같은 모델 연속 사용 금지** — 라운드마다 반드시 다른 모델
2. **regression 즉시 롤백** — 이전 PASS가 FAIL되면 해당 수정 취소
3. **10분 하드 타임아웃** — 전체 루프가 10분 초과 시 즉시 에스컬레이션
4. **원본 보존** — `draft.md.bak`은 절대 삭제하지 않음
5. **수정 내용 구체적 기록** — "수정함"이 아니라 "AI냄새 표현 12개 교체" 수준

## 에러 처리
- 라운드 중 CLI 타임아웃 → 해당 라운드 스킵, 다음 모델로 즉시 전환
- 3개 CLI 모두 다운 → Gemma 4 로컬. 그것도 실패 → 즉시 에스컬레이션
- `/blog-review` 재실행 실패 → 마지막 성공 리포트 기준으로 판단
