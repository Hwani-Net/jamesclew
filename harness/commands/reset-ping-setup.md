---
description: "5H/7D 리셋 시 규칙 재주입 Remote Trigger 등록"
user_invocable: true
---

# /reset-ping-setup — Rate Limit Reset Ping 설정

리밋 리셋 시점에 규칙 재주입 프롬프트를 자동 전송합니다.

## 실행 절차

1. 현재 리셋 시간 확인:
   ```bash
   bash D:/jamesclew/harness/scripts/register-reset-trigger.sh
   ```

2. Remote Trigger 등록/업데이트:
   - ToolSearch로 RemoteTrigger 로드 (또는 `schedule` skill 사용)
   - 5H ping + 7D ping 각각 등록
   - 프롬프트: `bash D:/jamesclew/harness/scripts/reset-ping-prompt.sh`의 출력

3. 검증:
   - RemoteTrigger(action: "list")로 등록 확인
   - 다음 리셋 시각 표시

## 자동 갱신

세션 중 `capture-reset-times.sh` hook이 `~/.harness-state/next-reset.json`을
업데이트하면, 수동으로 `/reset-ping-setup` 실행하여 Remote Trigger를 재등록.

(향후 자동화 검토: next-reset.json 변경 시 자동 재등록)

## 관련 파일

| 파일 | 역할 |
|------|------|
| `~/.harness-state/next-reset.json` | 5H/7D 리셋 시각 캐시 |
| `harness/scripts/register-reset-trigger.sh` | cron 계산 + 등록 지시 출력 |
| `harness/scripts/reset-ping-prompt.sh` | 리셋 시 주입할 프롬프트 출력 |

## 트리거 이름 규칙

- `claude-5h-reset-ping` — 5시간 롤링 윈도우 리셋 후 1분
- `claude-7d-reset-ping` — 7일 주간 풀 리셋 후 1분
