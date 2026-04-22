---
title: 하네스 작동 원리
type: explanation
diátaxis: Explanation
---

# 하네스 작동 원리

## 하네스의 4대 구성 요소

```
┌─────────────────────────────────────────────────────┐
│                   Claude Code CLI                    │
├──────────────┬──────────────┬──────────┬────────────┤
│  CLAUDE.md   │    hooks/    │commands/ │   MCP      │
│  (규칙 주입) │ (자동 개입)  │ (스킬)   │ (도구 확장) │
└──────────────┴──────────────┴──────────┴────────────┘
```

| 구성 요소 | 위치 | 역할 |
|----------|------|------|
| **CLAUDE.md** | `~/.claude/CLAUDE.md` | 모든 세션에 자동 로드되는 전역 규칙. 19개 섹션. |
| **hooks/** | `~/.claude/hooks/*.sh` | 도구 호출 전/후에 자동 실행되는 bash 스크립트. 잘못된 행동 차단. |
| **commands/** | `~/.claude/commands/*.md` | `/blog-pipeline`, `/qa` 등 슬래시 커맨드로 호출하는 스킬. |
| **MCP** | `settings.json` 등록 | Perplexity, Tavily, Stitch 등 외부 도구를 Claude Code에 주입. |

---

## 3-에이전트 구조 (Planner → Generator → Evaluator)

모든 복잡한 작업은 세 역할로 분리됩니다.

```
대표님 지시
    │
    ▼
[Planner — Opus]
 작업 분해, 우선순위 산정, 모델 라우팅 결정
    │
    ├──────────────────────────────────┐
    ▼                                  ▼
[Generator — Sonnet 서브에이전트]   [Generator — GPT-4.1]
 코드 작성, 파일 편집, 배포          콘텐츠 생성, 벌크 작업
    │                                  │
    └──────────────┬───────────────────┘
                   ▼
          [Evaluator — Codex + GPT-4.1 병렬]
           교차 검수, AI냄새 감지, 품질 판정
                   │
                   ▼
             Opus 최종 승인
                   │
                   ▼
             대표님께 보고
```

Generator와 Evaluator는 반드시 다른 모델을 사용합니다. 자기 검수(self-review)는 하네스 규칙상 금지되어 있습니다.

---

## 세션 수명과 hook 개입 시점

```
SessionStart
    │  ← [UserPromptSubmit] user-prompt.ts
    │    - 피드백 패턴 감지 → PITFALLS 기록 지시 주입
    │    - 빌드 요청 감지 → enforce-build-transition.sh 경고
    │
    ▼
Tool Use 루프
    │  ← [PreToolUse]
    │    - Write/Edit: 보호 파일 차단, 빌드 전환 규칙 확인
    │    - Bash: irreversible-alert.sh, bash-tool-blocker.sh
    │    - Tavily: tavily-guardrail.sh (search_depth 강제)
    │    - mcp__expect__screenshot: vision-routing-guard.sh
    │
    │  ← [PostToolUse]
    │    - Bash(firebase deploy): verify-deploy.sh → 200 응답 확인
    │    - Write/Edit: post-edit-dispatcher.sh, regression-autotest.sh
    │    - Bash: error-telegram.sh, loop-detector.sh
    │
    ▼
Stop
    │  ← [Stop] stop-dispatcher.sh
    │    - last_result.txt → 텔레그램 알림 전송
    │
PreCompact (컨텍스트 45%+)
    │  ← [PreCompact] precompact.sh
         - 옵시디언 세션 저장 실패 시 exit 2 → compact 차단
```

---

## 모델 라우팅 다이어그램

```
작업 유형
    │
    ├── 코드 작성/수정 ──────► Sonnet 서브에이전트 ──► Codex 리뷰
    ├── 코드 리뷰 ──────────► Codex + GPT-4.1 병렬 ──► Opus 판단
    ├── 콘텐츠 리뷰 ────────► GPT-4.1 (localhost:4141)
    ├── Vision 분석 ────────► Opus 직접 Read (Sonnet Vision 금지)
    ├── 웹 리서치 ──────────► Perplexity/Tavily MCP (5H 0)
    ├── 벌크/반복 ──────────► Gemma 4 로컬 (Ollama :11434)
    └── 최종 판단/커밋 ─────► Opus 직접
```

**비용 우선순위**: 외부 모델(5H 0) > Sonnet 서브에이전트(5H 느림) > Opus 직접(5H 빠름)

---

## 핵심 동작 규칙 요약

- **Ghost Mode**: 즉시 실행. 확인 질문 없음. 3회 재시도 후에만 보고.
- **Evidence-First**: 모든 보고에는 도구 출력 증거가 필요합니다.
- **Search-Before-Solve**: 막히면 `gbrain query` 먼저. 없으면 Tavily/Perplexity.
- **우선순위 공식**: `긴급도 + 수익영향 + 대표님대기 + ROI - 리스크` 점수 산정 후 정렬 실행.
