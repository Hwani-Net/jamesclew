---
title: pitfall-201 — OpenClaw hidden cron agentTurn으로 자율 진화 루프를 이어가려다 실패
slug: pitfall-201-openclaw-hidden-cron-agentturn-self-driven-evolution
date: 2026-05-26
type: pitfall
tags:
  - openclaw
  - cron
  - self-driven-evolution
  - discord
  - p206
severity: high
related:
  - pitfall-194-task-completed-without-external-evidence
  - pitfall-200-openclaw-nyongjong-pre-simulation-antipattern-mock-delegation
---

# pitfall-201 — hidden cron agentTurn은 자율 진화 루프가 아니다

## 증상

OpenClaw cron job `75b2e437-1954-41f3-8854-91f1084d38a0`가 P-204 critic watch 용도로 생성됐지만, 실행 후 `enabled=false`, `lastRunStatus=error`, `lastError=run openclaw cron (agent) failed` 상태가 됐다.

문제 job은 `payload.kind=agentTurn`, `delivery.mode=none`, `delivery.channel=last` 형태였다. 즉 실패해도 사용자나 오케스트레이터에게 보이는 결과가 보장되지 않았다.

## 원인

14:32~14:34 UTC gateway 로그에서 다음 증거가 확인됐다.

- `AGENTS.md` injected context truncation warning
- Discord guild message `reason=no-mention` skip 반복
- `Error: --thread-id must be a safe positive integer Telegram topic thread id`
- `No --agent specified; the job will run with the configured default agent`
- `cron: job run returned error status`
- `cron: disabling one-shot job after error`

핵심 원인은 숨은 cron agent turn을 진행 감시/자율 진화의 source of truth로 사용한 것이다. 여기에 Discord thread snowflake를 generic `--thread-id`처럼 다루는 channel option 오용, explicit agent target 누락, `delivery.mode=none`으로 인한 가시성 상실이 결합했다.

## 해결

P-206 규칙으로 영구화한다.

1. self-driven evolution, critic loop, progress watch, multi-step continuation, active project continuation에는 cron job 의존 금지. cron `agentTurn` + `delivery.mode=none`은 특히 금지.
2. 진행은 thread 안 실제 위임 메시지와 watchdog/P-203 증거로만 판단.
3. 지연 실행이 필요하면 state artifact를 쓰고, nyongjong 실제 mention을 포함한 visible wake/report를 남긴다.
4. agent 실행이 필요하면 explicit agent target과 deliveryStatus/state artifact를 검증한다.
5. Discord thread id를 다른 channel의 `--thread-id` 옵션 의미로 재사용하지 않는다.

## 재발 방지

- `/home/creator/.openclaw/workspace/AGENTS.md`에 `Self-driven Evolution (P-206)` 섹션 추가.
- `/home/creator/.openclaw/workspace/scripts/openclaw-p206-cron-agentturn-diagnose.js`로 cron job + gateway log window를 exit-0 JSON evidence로 진단.
- `/home/creator/.openclaw/workspace/scripts/openclaw-p206-cron-policy-audit.js`로 현재 cron 정책 위반을 exit-0 JSON evidence로 진단.
- `/home/creator/.openclaw/workspace/docs/solutions/openclaw-self-driven-evolution-cron-agentturn-p206-2026-05-26.md`에 agent-readable solution 기록.

## 검증 명령

```bash
node /home/creator/.openclaw/workspace/scripts/openclaw-p206-cron-agentturn-diagnose.js --job-id 75b2e437-1954-41f3-8854-91f1084d38a0 --log /tmp/openclaw/openclaw-2026-05-25.log --jobs /home/creator/.openclaw/cron/jobs.json --start 2026-05-25T14:32:00.000Z --end 2026-05-25T14:34:00.000Z
```
