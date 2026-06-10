---
description: Codex CLI Pro 단일 계정 OAuth 토큰 갱신 (14일 주기, refresh token 만료 회피).
argument-hint: "[check|--start]"
allowed-tools: Bash, Read, Write
---

# codex-refresh — Codex Pro 단일 계정 토큰 갱신

OpenAI Codex CLI는 ChatGPT OAuth refresh token이 약 14~15일마다 만료.

> **2026-06-07 체제 변경**: 6계정 로테이션 폐지 → **Pro 단일 계정 `hwanizero01@gmail.com` (plan=prolite)만 활성**.
> `~/.codex-accounts/account1.json`이 유일한 활성 백업. account2~6은 아카이브(만료/rate-limit, 갱신 안 함).

## 핵심 제약 (자동화 한계)

`codex login`은 브라우저 OAuth flow라 **사용자 직접 승인 필수**. 그 외(만료 감지, rm, cp, 검증)는 모두 자동.

## 사용법

### 1) 만료 감지만
```bash
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh check
```
- `OK — 토큰 유효` (exit 0): 갱신 불필요
- `EXPIRED — 갱신 필요` (exit 1): 갱신 시작

### 2) 갱신 (Pro 계정 1개만)

```bash
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh prepare 1   # rm auth.json
codex login                                                            # 브라우저 OAuth (hwanizero01@gmail.com)
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh save 1      # cp → account1.json
```

### 3) 검증
```bash
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh verify
```

account1.json swap → `codex exec "say pong"` ping → 401 없으면 PASS.

## 14일 주기 알림 (자동)

`/schedule` 또는 cron으로 14일마다 다음 명령 자동 실행:
```bash
bash D:/jamesclew/harness/scripts/codex-refresh-helper.sh check || \
  echo "[Codex] Pro 계정 토큰 갱신 필요. /codex-refresh 실행" | \
  bash $HOME/.claude/hooks/telegram-notify.sh user
```

EXPIRED 시 텔레그램 알림 → 사용자가 `/codex-refresh` 호출하여 갱신.

## ⚠️ 절대 금지 사항

`codex logout` 사용 금지. Codex CLI 0.96+ 버전부터 logout이 **서버측 OAuth revoke**까지 수행 → 백업 토큰이 무효화됨.

`rm ~/.codex/auth.json`만 사용 (helper.sh가 자동 적용).

참조: `D:/jamesclew/harness/pitfalls/pitfall-069-codex-logout-revokes-server-token.md`

## 산출물 위치

- 활성 백업: `~/.codex-accounts/account1.json` (account2~6 = 아카이브, 갱신 대상 아님)
- 활성 토큰: `~/.codex/auth.json`
- rotate 로그: `~/.harness-state/codex-rotation-state`
