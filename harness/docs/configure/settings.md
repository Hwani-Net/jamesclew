---
title: settings.json 키별 레퍼런스
type: reference
diátaxis: Reference
source: D:/jamesclew/harness/settings.json
lines: 469
---

# settings.json 레퍼런스

소스: `D:/jamesclew/harness/settings.json` (469줄)
배포 경로: `~/.claude/settings.json` (전역) 또는 `D:/jamesclew/.claude/settings.json` (프로젝트)

**수정 절차**: 소스를 편집 → `bash harness/deploy.sh` → Claude Code 재시작.
하네스 파일 수정 전 외부 모델(Codex/GPT-4.1) 검토를 거쳐야 합니다(충돌·회귀 방지).

---

## 최상위 키 일람

### `thinking`

```json
"thinking": { "budget_tokens": 10000 }
```

Opus의 extended thinking 토큰 예산. 복잡한 설계 작업에서 사용됩니다. 값을 높이면 더 깊이 추론하지만 토큰 소비가 증가합니다.

---

### `env`

```json
"env": {
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
  "ENABLE_PROMPT_CACHING_1H": "1",
  "CLAUDE_CODE_ENABLE_AWAY_SUMMARY": "1",
  "CLAUDE_STREAM_IDLE_TIMEOUT_MS": "180000"
}
```

| 키 | 설명 |
|----|------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Agent Teams 활성화 (v2.1.107+) |
| `ENABLE_PROMPT_CACHING_1H` | 프롬프트 캐싱 1시간. 반복 호출 비용 절감. |
| `CLAUDE_CODE_ENABLE_AWAY_SUMMARY` | 자리 비움 중 요약 생성. |
| `CLAUDE_STREAM_IDLE_TIMEOUT_MS` | 스트림 idle 타임아웃 180초. |

---

### `permissions`

```json
"permissions": {
  "allow": ["Bash(*)", "Read(*)", "Edit(*)", "Write(*)", ...],
  "deny":  ["Bash(rm -rf /)", "Bash(*format*C:*)", ...],
  "defaultMode": "bypassPermissions"
}
```

- **`defaultMode: "bypassPermissions"`**: 대부분의 도구 호출에서 승인 프롬프트를 건너뜁니다. 하네스 hook이 독립적으로 위험 명령을 차단하므로 이 설정이 안전합니다.
- **allow**: 명시적으로 허용할 도구 패턴. MCP 도구는 `mcp__서버명__도구명` 형식.
- **deny**: 절대 차단할 명령 패턴. hook보다 먼저 적용됩니다.

새 MCP를 allowlist에 추가하려면 `/less-permission-prompts` 를 실행하면 트랜스크립트를 스캔하여 자동 제안합니다.

---

### `hooks`

hook은 이벤트(PreToolUse / PostToolUse / Stop / SubagentStop / PreCompact)와 매처(도구 이름 패턴)로 구성됩니다.

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [
        {
          "type": "command",
          "command": "bash $HOME/.claude/hooks/verify-memory-write.sh",
          "timeout": 30000
        }
      ]
    }
  ]
}
```

| 필드 | 설명 |
|------|------|
| `matcher` | 도구 이름 정규표현식. `Write\|Edit`, `Bash`, `mcp__tavily__.*` 등. |
| `type` | `"command"` (bash 스크립트) 또는 `"http"` (직접 HTTP POST). |
| `command` | 실행할 bash 명령. `$HOME` 으로 경로 지정. |
| `timeout` | 밀리초. hook이 이 시간 내 응답하지 않으면 무시. |
| `if` | 조건 필터. `"Bash(*firebase deploy*)"` 처럼 특정 인자에만 적용. |

hook이 `exit 2` 를 반환하면 해당 도구 호출이 차단됩니다. `exit 0` 은 허용입니다.

---

### 등록된 주요 hook 목록

| 이벤트 | 매처 | hook 파일 | 역할 |
|--------|------|----------|------|
| PreToolUse | Write\|Edit | `verify-memory-write.sh` | 보호 파일(.env 등) 차단 |
| PreToolUse | Write\|Edit | `enforce-build-transition.sh` | 빌드 요청 시 plan 없으면 차단 |
| PreToolUse | `mcp__tavily__.*` | `tavily-guardrail.sh` | `search_depth=advanced` 강제 차단 |
| PreToolUse | `mcp__expect__screenshot` | `vision-routing-guard.sh` | Sonnet Vision 경고 |
| PreToolUse | Bash | `irreversible-alert.sh` | 파괴적 명령 defer 게이트 |
| PreToolUse | Bash | `bash-tool-blocker.sh` | deny rule 추가 매칭 |
| PreToolUse | `Bash(git commit *)` | `pre-commit-conventional.sh` | Conventional Commits 강제 |
| PostToolUse | `Bash(*firebase deploy*)` | `verify-deploy.sh` | 배포 후 HTTP 200 확인 |
| PostToolUse | Write\|Edit | `post-edit-dispatcher.sh` | 편집 후 품질 게이트 |
| PostToolUse | Write\|Edit | `regression-autotest.sh` | 회귀 감지 |
| PostToolUse | Bash | `loop-detector.sh` | 무한 루프 감지 |
| Stop | — | `stop-dispatcher.sh` | 텔레그램 알림 전송 |
| SubagentStop | — | `verify-subagent.sh` | 서브에이전트 결과 검증 |
| PreCompact | — | `pre-compact-snapshot.sh` | 옵시디언 저장 실패 시 compact 차단 (exit 1) |

---

## deploy.sh로 변경사항 배포

`D:/jamesclew/harness/settings.json` 을 수정한 후:

```bash
bash harness/deploy.sh
```

이 명령은 `settings.json` 을 `~/.claude/settings.json` 에 복사합니다. Claude Code를 재시작해야 적용됩니다.
