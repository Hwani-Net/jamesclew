# P-115: REPL 전용 slash command를 외부 자동화 시도 — `/compact`는 CLI 우회 불가

- **발견**: 2026-05-04 (대표님 직접 지적: "compact 자동 실행이 안되고 있어. 다른 방법은 없는지 최신 자료를 찾아봐.")
- **프로젝트**: 하네스 자체 (commands/저장.md + stop-dispatcher.sh의 desktop-control 클립보드 방식)
- **사건 요약**: `/compact` 명령을 desktop-control(클립보드 + ctrl+v + Enter)으로 자동화 시도. 포커스 문제로 동작 안 함. 검색 결과(researcher 위임) — `/compact`는 **REPL 전용**이라 CLI/SDK/hook 어떤 외부 메커니즘으로도 직접 호출 불가가 Anthropic 공식 입장. 올바른 자동화는 `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` 환경변수로 **임계값을 낮춰서 내장 자동 compact 발동**. P-014(학습 데이터 의존)·P-111(코드 존재 ≠ 동작) 변형.

## 증상

1. **REPL 전용 slash command를 외부 자동화 가능한 것으로 가정**: `/compact`, `/clear`, `/exit` 등은 Claude Code REPL 내부에서만 동작. CLI 옵션·SDK 메서드·hook 출력 어느 것으로도 직접 발동 불가.
2. **클립보드 + ctrl+v 우회 시도 → 포커스 의존 + 비결정적**: desktop-control이 어느 창에 ctrl+v를 보내는지 보장 안 됨. Claude Code 입력창이 활성 상태가 아닐 수 있음.
3. **공식 문서 미확인 상태에서 자동화 절차를 CLAUDE.md에 명시**: 결과적으로 동작 안 하는 절차가 표준으로 등록됨.

## 원인

1. **slash command와 CLI flag의 차이 인지 부족**:
   - slash command(`/compact`, `/clear`): REPL 내부 키 입력으로만 발동
   - CLI flag(`--resume`, `-p`): 프로세스 spawn 옵션으로 외부 발동 가능
   - 둘은 다른 메커니즘. 혼동하면 안 됨.
2. **GitHub Issue #41818** ("compactAtPercent 같은 명령으로 발동" 요청)이 미구현 상태인 걸 검증 안 함
3. **공식 환경변수 `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` 존재를 모름** — 이게 정답이었음
4. **1M 컨텍스트 모델은 `CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000` 함께 설정 필요**: PCT만 설정하면 200K 기준 45% = 90K에서 너무 일찍 발동

## 해결

### 즉시 (이번 세션)

1. **settings.json env 블록 추가**:
   ```json
   {
     "env": {
       "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "45",
       "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "1000000"
     }
   }
   ```

2. **PreCompact hook 옵시디언 저장 로직 활용** — 이미 `pre-compact-snapshot.sh`에 구현되어 있음 (matcher: `auto|manual`). 자동 compact 발동 직전 저장 + 실패 시 차단.

3. **commands/저장.md의 desktop-control 클립보드 절차 deprecate**: 환경변수가 임계값 도달 시 자동 compact를 처리하므로 더 이상 필요 없음.

### 구조적 (다음 세션)

#### slash command vs CLI 메커니즘 매트릭스

```yaml
# claude-code-mechanism.yaml
slash_commands:
  /compact: REPL only — automate via CLAUDE_AUTOCOMPACT_PCT_OVERRIDE
  /clear: REPL only — automate via session restart
  /resume: REPL only — automate via `claude --resume`
cli_flags:
  --resume: Process spawn argument
  -p / --print: Non-interactive mode (slash commands NOT supported)
hooks:
  PreCompact: matcher=auto/manual, runs BEFORE compact
  PostCompact: runs AFTER compact
  Stop: each turn end (NOT compact trigger)
env_vars:
  CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: "45" (auto compact trigger threshold)
  CLAUDE_CODE_AUTO_COMPACT_WINDOW: "1000000" (1M model window)
```

#### 외부 자동화 시도 전 의무 체크리스트

1. 해당 명령이 REPL 전용인가 CLI인가?
2. CLI라면 spawn 옵션 가능
3. REPL이라면 환경변수/설정으로 우회 가능한지 검색
4. 우회 안 되면 **외부 자동화 시도 금지** — 사용자에게 수동 입력 요청

## 재발 방지

1. **이 PITFALL을 SessionStart에 surface**: P-014, P-111, P-112, P-113, P-114와 함께
2. **commands/저장.md 업데이트**: desktop-control 절차 → 환경변수 안내
3. **CLAUDE.md Quality Gates 추가**:
   "외부 자동화 시도 전 — Anthropic 공식 문서로 'CLI/hook/env로 발동 가능한가' 검증. REPL 전용이면 자동화 시도 금지."

## 관련 PITFALL

- P-014: 학습 데이터 의존 금지 — 환경변수의 존재를 추측 없이 검색해야 했음
- P-111: 코드 존재 ≠ 코드 동작 — desktop-control 명령 발송 ≠ slash command 실행
- P-112: 컨텍스트 잔량 검증 없이 작업 미루기 — compact 시점 판정에서 비슷한 패턴
- P-113: path 불일치 dead code — 외부 자동화 메커니즘 vs 실 호출 매개체 불일치

## 적용 위치

- 모든 Claude Code slash command 자동화 시도
- desktop-control / claude-in-chrome 외부 입력 자동화 시도
- 새 hook 작성 시 trigger 메커니즘 검증
- CLAUDE.md, commands/*.md 의 자동화 절차 명시 시
