# P-116: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` 환경변수 전역 적용 — Sonnet 200K 세션 조기 compact

- **발견**: 2026-05-05 (대표님 직접 지적: "sonet에서도 40%쯤 되면 compact가 진행되고 있어")
- **프로젝트**: 하네스 자체 (settings.json env 블록)
- **사건 요약**: P-115 해결책으로 settings.json env에 `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=45` + `CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000` 추가. Anthropic 공식 문서 명시: "Applies to **both main conversations and subagents**. **Global** setting (applies to all models)." → Sonnet 200K 세션에서도 45% = 90K에서 조기 compact 발동. P-115의 OpusOnly 가정이 틀렸음. P-014(학습 데이터 의존) 변형.

## 증상

1. **Sonnet 200K 세션이 약 40~45% 사용량에서 자동 compact**: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=45` 적용 결과 — 200K * 45% = 90K. Sonnet 사용자 입장에선 "너무 일찍 잘림".
2. **`CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000`은 Sonnet에서 200K로 자동 cap**: 공식 docs 명시. 무해하나 무의미.
3. **`Math.min()` clamp 버그 (GitHub Issue #31806)**: PCT 값을 default(83.5%) 이상으로 올릴 수 없음. `min(userThreshold, defaultThreshold)`. Opus만 트리거하려고 PCT를 90%로 설정하는 우회 불가.
4. **모델별 환경변수 분리 공식 미지원**: `CLAUDE_AUTOCOMPACT_PCT_OPUS` 같은 변수 없음. settings.json 모델별 분기 불가.

## 원인

1. **공식 docs "Global setting" 명시를 P-115 작성 시 누락**: 적용 범위 검증 없이 환경변수 추가
2. **Opus 전용 가정**: 1M 컨텍스트 모델 기준 설계인데 모든 모델에 동일 적용 — 200K Sonnet은 45% = 90K로 너무 빠름
3. **외부 모델 검수 누락**: 하네스 settings.json 변경 전 Codex/GPT-4.1 검수 의무(CLAUDE.md Quality Gates) 미준수
4. **2수 앞 사고 부족**: "이 설정이 Sonnet 메인/Sonnet 서브에이전트에 어떤 영향?" 사전 점검 안 함

## 해결

### 즉시 (이번 세션)

1. **settings.json env 두 변수 제거** (2026-05-05 적용):
   ```json
   "env": {
     // CLAUDE_AUTOCOMPACT_PCT_OVERRIDE 제거
     // CLAUDE_CODE_AUTO_COMPACT_WINDOW 제거
     ...
   }
   ```
2. **deploy.sh 실행**: 모든 프로젝트 글로벌 적용 → Sonnet 조기 compact 즉시 차단
3. **모든 모델은 default(~83.5%)로 복귀**: Opus 1M = 835K, Sonnet 200K = 167K — 둘 다 안전

### 구조적 (Opus 자동 compact 복원 옵션)

P-007 정책(Opus 45% compact)의 자동화는 환경변수 글로벌이 답이 아님. **shell environment가 settings.json env보다 우선**(공식 확인)이므로 세션별 주입:

#### 옵션 A: PowerShell function (권장)

```powershell
# $PROFILE 에 추가
function Start-ClaudeOpus {
    $env:CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "45"
    $env:CLAUDE_CODE_AUTO_COMPACT_WINDOW = "1000000"
    claude $args
}
function Start-ClaudeSonnet { claude --model sonnet $args }
```

#### 옵션 B: 프로젝트별 `.claude/settings.local.json`

Opus 메인으로 사용하는 프로젝트(jamesclew)에만 env 적용 — 다른 프로젝트 Sonnet 세션 영향 없음.

#### 옵션 C: PreCompact hook 모델 분기 차단

PreCompact hook에서 모델 확인 후 Sonnet이면 `exit 2`로 차단 — 단, 트리거 자체는 못 막아 무한 차단 루프 위험. **비권장**.

#### 옵션 D: 자동화 포기, 수동 `/저장` 복귀

가장 안전. P-007 자동화 메리트는 작음 (Opus 1M에서 default 83.5% = 835K도 충분히 늦지만 PreCompact hook이 옵시디언 저장 처리하므로 OK).

## 재발 방지

1. **하네스 settings.json env 추가 시 의무 체크리스트**:
   - [ ] Anthropic 공식 docs에서 적용 범위 확인 (Global vs Per-Model vs Per-Subagent)
   - [ ] 모든 모델(Opus 1M, Sonnet 200K, Haiku) 컨텍스트 윈도우 기준 PCT 영향 시뮬레이션
   - [ ] Codex + GPT-4.1 외부 모델 사전 검수
   - [ ] 다른 프로젝트(Sonnet 메인) 영향 평가
2. **이 PITFALL을 SessionStart에 surface**: P-014, P-115와 함께
3. **CLAUDE.md Quality Gates 보강**: "settings.json env 추가 전 — 적용 범위(Global/Per-Model) 공식 docs 확인 + 모든 모델 영향 평가 의무"
4. **P-115 업데이트**: "Sonnet 영향 주의" 노트 추가

## 관련 PITFALL

- P-014: 학습 데이터 의존 금지 — 환경변수 동작 추측하지 말고 docs 검증
- P-007: Opus 45% compact 정책 — 자동화 메커니즘 재설계 필요
- P-115: REPL 전용 slash command — 환경변수 우회 발견은 옳았으나 적용 범위 검증 누락
- P-111: 코드 존재 ≠ 코드 동작 — 환경변수 등록 ≠ 모든 모델에서 의도대로 동작

## 적용 위치

- 모든 settings.json env 블록 추가/수정
- 자동 compact 임계값 정책 변경
- 모델별 환경변수 분리 시도

## 외부 검증

- 공식 docs: [code.claude.com/docs/en/env-vars](https://code.claude.com/docs/en/env-vars) (2026-05-05 확인)
- GitHub Issue #31806: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE cannot raise threshold above default` (OPEN, Math.min clamp 버그)
- GitHub Issue #42817: Auto-compact disable 불가
- GitHub Issue #53065: advisor() 토큰 인플레로 조기 compact 트리거
