---
slug: pitfall-134-hook-timeout-not-propagated-to-child
title: Hook timeout이 외부 CLI 자식 프로세스에 전파되지 않아 무한 hang
date: 2026-05-08
tags: [hooks, stop-hook, timeout, gbrain, hang, claude-code]
severity: high
---

# Hook timeout이 외부 CLI 자식 프로세스에 전파되지 않아 무한 hang

## 증상
- Claude Code Stop hook 7번째(`dialectic-pattern-extractor.sh`)가 **timeout 45000ms 설정에도 10분+ hang**
- 화면 하단: "Fiddle-faddling... (running stop hooks 7/8) 10m 15s | 11.0k tokens, thought for 22s"
- 대표님이 새 응답을 받지 못하고 계속 대기 상태
- Stop hook 8/8까지 안 가고 7번째에서 멈춤

## 원인
1. 스크립트 내 `gbrain put "$SLUG" --content "$CONTENT"` 호출
2. gbrain CLI가 임베딩 API(외부 네트워크) 응답 대기 중 무한 hang
3. **Claude Code의 hook timeout 설정은 hook 스크립트 자체에는 SIGTERM 전송하지만, 그 자식 프로세스(curl/gbrain/python 등)까지는 전파되지 않음**
4. 결과: 부모 bash는 자식 gbrain의 종료를 기다리느라 timeout 지났어도 무한 대기
5. `set -euo pipefail` + `if cmd; then` 패턴은 자식 종료 의존도가 높아 hang 발생 시 무방어

## 해결
### 즉시 (이번 케이스)
```bash
# Before
if gbrain put "$SLUG" --content "$CONTENT" >/dev/null 2>&1; then

# After
if timeout 20 gbrain put "$SLUG" --content "$CONTENT" >/dev/null 2>&1; then
```
- 외부 CLI 호출은 **반드시 `timeout N` 명령으로 wrap**
- gbrain은 보통 1-3초. 20초면 충분.

### 구조적 해소
- 무거운 외부 호출(임베딩, gbrain put, 텔레그램 멀티 send)은 **Stop hook이 아닌 PostCompact**로 옮김
- Stop hook은 30초 이내 마치는 가벼운 작업만 (telegram-notify, session-learning 등)
- 이번 케이스: dialectic-pattern-extractor를 Stop → PostCompact로 이동 (timeout 30000)

## 재발 방지 체크리스트
다음 외부 CLI 호출은 **모두 timeout wrap 필수**:
- [ ] `gbrain put / query / import / sync` (네트워크 + 디스크)
- [ ] `curl` (`--max-time` 사용 — gbrain은 별도)
- [ ] `codex exec` (외부 API)
- [ ] `npx @smithery/...` MCP 호출
- [ ] `firebase deploy / gh-pages` (배포)
- [ ] `docker / podman` 명령
- [ ] `npm install / pnpm install` (네트워크)
- [ ] `python3` 스크립트 중 외부 API 호출 포함된 것

## 진단 명령
```bash
# 모든 hook 스크립트에서 timeout wrap 안 된 외부 CLI 호출 찾기
grep -rE "gbrain (put|query|import|sync)|^curl |codex exec" D:/jamesclew/harness/hooks/*.sh \
  | grep -v "timeout [0-9]"
```

## 관련 파일
- `D:/jamesclew/harness/hooks/dialectic-pattern-extractor.sh` (line 198)
- `D:/jamesclew/harness/settings.json` (Stop 배열에서 PostCompact로 이동)

## 인용 (대표님 원문)
> "너는 fiddle-faddling이라며 hang 중이라는 것이야"

대표님 직접 시각 관찰. Stop hook의 무한 hang 패턴은 Claude Code 자체로 해결 불가, 하네스 측에서 timeout wrap이 유일한 방어선.
