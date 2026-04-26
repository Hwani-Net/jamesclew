---
description: Codex CLI 6계정 OAuth 토큰 갱신 가이드. 14일마다 호출 (refresh token 만료 회피). PITFALL #069 (codex logout 금지) 자동 적용. 인자 없으면 만료 자동 감지 + 6계정 순차 가이드.
argument-hint: "[check|--start|--account N]"
allowed-tools: Bash, Read, Write
---

# codex-refresh — Codex 6계정 토큰 갱신

OpenAI Codex CLI는 ChatGPT OAuth refresh token이 약 14~15일마다 만료. `~/.codex-accounts/account1~6.json` 6개 백업본을 손으로 갱신하던 작업을 자동화.

## 핵심 제약 (자동화 한계)

`codex login`은 브라우저 OAuth flow라 **사용자 직접 승인 필수**. 그 외(만료 감지, rm, cp, 검증)는 모두 자동.

## 사용법

### 1) 만료 감지만
```bash
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh check
```
- `OK — 토큰 유효` (exit 0): 갱신 불필요
- `EXPIRED — 갱신 필요` (exit 1): 6계정 순차 갱신 시작

### 2) 6계정 순차 갱신 (정공법)

**계정 1**:
```bash
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh prepare 1   # rm auth.json
codex login                                                            # 브라우저 OAuth (계정 1)
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh save 1      # cp → account1.json
```

**계정 2~6 동일 반복** (helper.sh 출력 마지막 줄에 다음 명령 자동 안내).

### 3) 검증 (6계정 모두 PASS 확인)
```bash
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh verify
```

각 account*.json을 swap → `codex exec "say pong"` ping → 401 없으면 PASS.

## 14일 주기 알림 (자동)

`/schedule` 또는 cron으로 14일마다 다음 명령 자동 실행:
```bash
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh check || \
  echo "[Codex] 6계정 토큰 갱신 필요. /codex-refresh 실행" | \
  bash $HOME/.claude/hooks/telegram-notify.sh user
```

EXPIRED 시 텔레그램 알림 → 사용자가 `/codex-refresh` 호출하여 갱신.

## ⚠️ 절대 금지 사항

`codex logout` 사용 금지. Codex CLI 0.96+ 버전부터 logout이 **서버측 OAuke OAuth revoke**까지 수행 → 백업해 둔 다른 계정 토큰이 무효화됨.

`rm ~/.codex/auth.json`만 사용 (helper.sh가 자동 적용).

참조: `D:/jamesclew/harness/pitfalls/pitfall-069-codex-logout-revokes-server-token.md`

## 산출물 위치

- 백업: `~/.codex-accounts/account1.json` ~ `account6.json`
- 활성 토큰: `~/.codex/auth.json` (codex-rotate.sh가 매 호출마다 swap)
- rotate 로그: `~/.harness-state/codex-rotation-state`
