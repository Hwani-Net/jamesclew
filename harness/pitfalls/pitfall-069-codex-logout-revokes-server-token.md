---
slug: pitfall-069-codex-logout-revokes-server-token
title: "Codex CLI logout이 서버측 OAuth 토큰 revoke까지 함 — 멀티계정 갱신 시 백업본 무효화"
date: 2026-04-26
tier: raw
tags:
  - pitfall
  - codex-cli
  - multi-account
  - oauth
  - rotate
versions:
  - "@openai/codex@0.98.0"
upstream:
  - https://developers.openai.com/codex/auth
  - https://developers.openai.com/codex/changelog
  - https://github.com/openai/codex/issues/2557
---

# 증상

`~/.codex-accounts/`에 백업해 둔 6개 계정 인증 파일을 `codex-rotate.sh`로 로테이션 사용 중,
6계정 전부 갱신하려고 다음 절차를 반복 시:

```bash
codex logout
codex login
cp ~/.codex/auth.json ~/.codex-accounts/accountN.json
```

직전에 백업한 account1.json도 서버에서 토큰 revoke되어 다음 사용 시 401.

# 원인

Codex CLI 최근 버전(0.98.0 시점) security 강화로 `codex logout` 명령이
**로컬 ~/.codex/auth.json 삭제 + 서버측 OAuth refresh token revoke** 둘 다 수행.

이전 버전(<0.5x)은 로컬 파일만 삭제 → 백업본은 서버에 살아있어 유효.
최근 버전은 GitHub Issue #2557 기반 보안 개선으로 서버 revoke까지 강제.

따라서 multi-account rotate 시 logout 사용은 직전 계정 토큰을 무효화하는 부작용.

# 해결 (안전한 갱신 절차)

`codex logout` 사용 금지. 로컬 파일만 삭제:

```bash
# === 계정 1 ===
codex login                                              # OAuth flow → 새 auth.json 생성
cp ~/.codex/auth.json ~/.codex-accounts/account1.json

# === 계정 2 (logout 안 함, rm만 사용) ===
rm ~/.codex/auth.json                                    # 로컬 파일만 삭제, 서버 unaware
codex login                                              # 다른 ChatGPT 계정 로그인
cp ~/.codex/auth.json ~/.codex-accounts/account2.json

# === 계정 3~6 동일: rm → codex login → cp ===
```

`rm`은 OAuth revoke 요청을 보내지 않으므로 백업한 토큰들은 서버에 살아있어 rotate 시 유효.

# 재발 방지

- codex-rotate.sh / 멀티계정 갱신 가이드에서 `logout` 명령 절대 사용 금지 명시
- harness/scripts/codex-rotate.sh 헤더 주석에 본 PITFALL 슬러그 참조 추가 권장
- 단일 계정 사용 환경에서는 logout 안전 (서버 revoke가 의도된 동작)
