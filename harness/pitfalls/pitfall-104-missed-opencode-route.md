---
slug: pitfall-104-missed-opencode-route
title: 사용자 환경 사전 인벤토리 누락 — OpenCode/Antigravity OAuth 경로 놓침
tags: [premature-conclusion, search-before-solve, environment-discovery]
date: 2026-05-03
재발: 6회차
---

# 증상
"외부에서 Antigravity quota 검증 불가능" 결론 후 대표님 지적: "OpenCode로 Antigravity OAuth 호출했던 건데 동일 방식으로 시도했나?"
실제 확인 결과 `~/.config/opencode/antigravity-accounts.json` (7.9KB, Apr 14) + opencode v1.3.0 이미 설치됨. 14초 만에 호출 성공.

# 원인
1. 처음 외부 호출 경로 조사 시 `gemini` CLI만 확인하고 `opencode` 미확인
2. `~/.gemini/`, `AppData\Roaming\Antigravity\`만 탐색하고 `~/.config/opencode/` 미탐색
3. 대표님이 과거에 사용했던 도구를 가정하지 않고 새로 찾으려 함

# 해결
검증/연동 작업 시작 시 사용자 환경 인벤토리 우선:
1. `which {tool}` — 관련 CLI 모두 확인 (claude, gemini, opencode, codex, copilot 등)
2. `ls ~/.config/`, `ls $APPDATA/` — 설정 디렉토리 전수 확인
3. `~/.{tool}*` 모두 탐색 (`.gemini`, `.claude`, `.opencode`, `.codex` 등)
4. 대표님 환경에 이미 구축된 도구를 우선 활용 — 새 도구 도입은 마지막

# 재발 방지
"외부 호출 불가능" 보고 전 체크리스트:
- [ ] OpenCode (gemini/anthropic/google plugin) 확인
- [ ] copilot-api 프록시 확인 (localhost:4141)
- [ ] HydraTeams 프록시 확인 (localhost:3456)
- [ ] 관련 npm 패키지 (`npm list -g`) 확인
- [ ] `~/.config/`, `$APPDATA/`, `$LOCALAPPDATA/Programs/` 전수
- [ ] `which` 명령으로 5개 이상 관련 CLI 확인

이전 4건의 PITFALL (101~103)이 이 1건으로 일부 무효화됨 — pitfall-101은 "외부 호출 불가능"이라 했으나 OpenCode 경로 존재하므로 정정 필요.
