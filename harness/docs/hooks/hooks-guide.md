# 훅 작성 및 디버깅 가이드

> How-To | 대상: JamesClaw 하네스 관리자 | 최종 업데이트: 2026-04-18

---

## 1. 훅이 필요한 순간

훅은 Claude Code가 도구를 사용하기 **직전(PreToolUse)** 또는 **직후(PostToolUse)**에 실행되는 bash 스크립트입니다. 다음 세 가지 목적으로 투입합니다.

- **행위 자동화**: 특정 도구 호출 시 알림 발송, 로그 기록 등 부가 작업을 자동 실행
- **규칙 강제**: 금지 패턴(destructive 명령, 잘못된 파일 경로)을 차단하거나 경고 주입
- **증거 수집**: 모든 변경·배포 기록을 `~/.harness-state/`에 누적하여 감사 가능하게 유지

---

## 2. 훅 종류 선택 가이드

| 목적 | 훅 타입 | 종료 코드 / 반환 |
|------|---------|----------------|
| 도구 실행 **완전 차단** | PreToolUse | `exit 2` |
| 도구 실행 전 **사용자 확인** (v2.1.89+) | PreToolUse | JSON `permissionDecision: "defer"` |
| **경고 메시지만** 주입 (차단 안 함) | PostToolUse | JSON `systemMessage` 필드 |
| 실행 후 **로그·알림** | PostToolUse | `exit 0` |

차단이 필요없는 상황에서 `exit 2`를 남발하면 에이전트의 자율성이 저하됩니다. 경고로 충분하면 PostToolUse + systemMessage를 사용하십시오.

---

## 3. 훅 작성 템플릿

```bash
#!/bin/bash
# hook-name.sh — 한 줄 설명
# 이벤트: PreToolUse | PostToolUse
# 대상 도구: Bash | Write | Edit | ...

# 1. stdin에서 JSON 입력 수신
INPUT=$(cat)

# 2. 필요한 필드 파싱 (jq 사용)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# 3. 조건에 해당하지 않으면 즉시 통과
[ -z "$CMD" ] && exit 0

# 4. 로직 실행
STATE_DIR="$HOME/.harness-state"
mkdir -p "$STATE_DIR"

if echo "$CMD" | grep -q "위험_패턴"; then
  # 차단 시: hookSpecificOutput + exit 2
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"차단 이유 설명"}}'
  exit 2
fi

# 5. 경고만 주입 시 (PostToolUse)
# echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"경고 내용"}}'

exit 0
```

**핵심 규칙**:
- `exit 0` = 통과, `exit 2` = 차단, `exit 1` = 에러(훅 자체 오류)
- `hookSpecificOutput` JSON은 Claude가 다음 턴에 컨텍스트로 읽습니다
- stderr 출력은 디버그용이며 Claude에게 전달되지 않습니다

---

## 4. settings.json 등록

`D:/jamesclew/harness/settings.json` (deploy 후 `~/.claude/settings.json`에 반영)에 훅을 등록합니다.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/my-hook.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

주요 필드:

| 필드 | 설명 | 예시 |
|------|------|------|
| `matcher` | 대상 도구명 | `"Bash"`, `"Write"`, `"Edit"` |
| `timeout` | 초 단위. 초과 시 훅 건너뜀 | `10` (기본), 긴 작업은 `30` |
| `if` | 조건부 실행 (선택) | `"env.CI == '1'"` |

---

## 5. 디버깅

**로그 확인**

```bash
# 훅이 기록하는 상태 파일들
ls ~/.harness-state/
# irreversible.log, session_changes.log, api_cost_log.jsonl 등
```

**수동 테스트** — 훅을 실제 Claude 없이 직접 실행합니다.

```bash
# PreToolUse 입력 JSON 모의
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/test"}}' \
  | bash D:/jamesclew/harness/hooks/irreversible-alert.sh

# 종료 코드 확인
echo "exit code: $?"
```

**자주 발생하는 문제**

| 증상 | 원인 | 해결 |
|------|------|------|
| 훅이 실행되지 않음 | matcher 오탈자, deploy 안 됨 | `bash harness/deploy.sh` 재실행 |
| 모든 도구가 차단됨 | `exit 2` 조건이 너무 넓음 | 조건 좁히기, `exit 0` 폴백 확인 |
| timeout 초과 | 훅 내부 외부 호출이 느림 | timeout 값 늘리거나 비동기 처리 |
| jq 파싱 실패 | INPUT이 빈 값 | `[ -z "$INPUT" ] && exit 0` 추가 |

---

## 6. 안티패턴

- **timeout 무한 설정 금지**: 훅이 멈추면 Claude 전체가 멈춥니다. 최대 30초.
- **stderr 과다 출력 금지**: 훅의 stderr는 Claude에게 전달되지 않아 디버그 혼란만 증가합니다.
- **INPUT 없이 추측 금지**: `jq` 파싱 실패를 `// empty`로 처리하고 빈 값이면 `exit 0`.
- **하향 나선 금지**: 재시도 후 상태가 악화되면 훅 로직 수정 전 대표님께 보고.

---

## 7. 실전 예시: irreversible-alert.sh 분해

`D:/jamesclew/harness/hooks/irreversible-alert.sh`는 비가역 명령(git force push, rm -rf, DROP TABLE 등)을 감지하고 텔레그램 알림을 발송하는 PreToolUse 훅입니다.

```bash
# 핵심 로직 요약
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

case "$CMD" in
  *"git push --force"*)   SEVERITY="critical" ;;
  *"rm -rf"*)             SEVERITY="high"     ;;
  *"firebase deploy"*)    SEVERITY="medium"   ;;
esac

# medium: 로그만, 텔레그램 미전송
# high/critical: 텔레그램 알림 + additionalContext 주입
# 차단(exit 2)은 하지 않음 — 경고만
```

차단 대신 알림을 선택한 이유: 비가역 작업도 의도된 경우가 있습니다. 훅은 감사 증거를 남기고 대표님이 인지하도록 돕는 역할이며, 최종 판단은 에이전트가 합니다.

---

## 관련 파일

- 소스: `D:/jamesclew/harness/hooks/` (37개 훅)
- 설정: `D:/jamesclew/harness/settings.json`
- 상태: `~/.harness-state/`
- 배포: `bash harness/deploy.sh`
