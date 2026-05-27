---
title: pitfall-216 — OpenClaw thread 작업이 길어지면 컨텍스트 오염으로 산출물 품질 하락
slug: pitfall-216-openclaw-context-refresh-session-cleanup
date: 2026-05-26
type: pitfall
tags:
  - openclaw
  - nyongjong
  - context-refresh
  - session-cleanup
  - p206
  - p205
severity: medium
related:
  - pitfall-205-openclaw-project-isolation-thread-per-project
  - pitfall-206-openclaw-cron-fire-error-auto-disable-without-fallback
  - pitfall-214-openclaw-autonomous-continuation-prompt-overnight
---

# pitfall-216 — thread 작업 누적 시 명시적 리프레시 명령으로만 새 세션을 spawn한다

## 증상

OpenClaw thread 안 작업이 20~50 사이클 이상 누적되면 nyongjong / codex-main / jamesclaw-cc 응답 품질이 다음과 같이 하락했다.

- 같은 결정을 반복 (이전 사이클에서 정해진 톤을 다시 묻거나 동일 후보를 재추출)
- 사용자가 명시한 제약 조건 망각 (예: "쿠팡 파트너스만" 명시했는데 다른 쇼핑몰 후보 추가)
- 사이클 사이 응답 시간 점진 증가 (컨텍스트 토큰 누적 → 추론 부담)
- 외부 모델(codex / ollama) 호출이 thread 안 전체 히스토리를 전달하려다 token limit 부딪힘

P-205 thread per project 격리는 했지만, **단일 thread 안에서 컨텍스트 오염**이 누적됐다.

## 원인

장기 thread에서 nyongjong이 매 사이클 thread 전체 히스토리를 컨텍스트로 받아들이는 default 동작이 작동했다. 사이클 수가 누적될수록 토큰 비용 + 추론 품질 모두 악화됐다.

cron 자동화로 주기적 컨텍스트 리프레시를 시도한 적이 있었지만, P-206(cron fire error auto-disable)에 의해 1회 실패 후 자동 비활성 → 후속 0 사이클 → 컨텍스트 오염 무한 누적.

## 해결

P-216 규칙으로 영구화한다.

1. **사용자가 명시적으로 리프레시 명령**을 #작업-요청(마스터) 채널에서 발송한다. 키워드:
   - "thread 세션 리프레시"
   - "요약하고 새 세션"
   - "컨텍스트 청소"
   - "<project_slug> 새 thread"
2. **nyongjong 리프레시 동작**:
   - 현재 thread 상태 파일/로그 / 산출물 mtime / 사용자 결정 이력 / 결재 이력을 요약 (3~5문장)
   - 새 thread spawn (또는 동일 thread + 요약 주입)
   - 새 세션 진입 시 요약을 SOUL.md / 상태 artifact / 메시지 첫 줄에 명시
   - 옛 thread 안에 "🔄 컨텍스트 리프레시 완료 — 새 세션 <new_thread_link>" 공지
3. **cron 자동화 보류 (P-206 위험)**:
   - 주기적 자동 리프레시는 cron one-shot fire error 시 자동 비활성 위험 (P-206)
   - 정공법: 사용자가 마스터 채널에서 명시 명령
   - 향후 cron 신뢰성 회복 시점에 재검토 (현재 미설계)
4. **자동 알림 (관찰만, 동작 X)**:
   - thread 사이클 ≥ 30회 도달 시 nyongjong이 "컨텍스트 누적 30사이클 — 리프레시 검토 필요" 알림을 마스터 채널에 1회 발송
   - 알림 후에도 사용자 명령 없으면 그대로 진행 (강제 리프레시 X)
5. **리프레시 후 산출물 연속성**:
   - 새 세션이 옛 산출물 path / version / hash를 인지해야 함
   - 요약에 "v<N> = path = hash" 형식으로 명시
   - 새 세션의 다음 산출물은 v<N+1>로 이어짐

## 재발 방지

- `/home/creator/.openclaw/workspace/AGENTS.md`에 `Context Refresh — Session Cleanup (P-216)` 섹션 추가.
- nyongjong 시스템 프롬프트에 "리프레시 키워드 4개 + 요약 형식" 룰 추가.
- jamesclaw-cc 메인 세션 CLAUDE.md "핵심 정책"에 P-216 한 줄 추가됨 (2026-05-26).
- 검증 스크립트: `/home/creator/.openclaw/workspace/scripts/openclaw-p216-context-cycle-monitor.js` (thread 사이클 수 + 알림 발송 이력, exit-0 JSON).

## 안티패턴

- cron 자동 리프레시 등록 → P-206 fire error 발생 시 비활성화 → 후속 0 → 오염 누적
- nyongjong이 사용자 명령 없이 임의로 리프레시 → 진행 중 사이클 단절
- 리프레시 시 요약 누락 → 새 세션이 옛 산출물 미인지 → v<N> 재작업
- 옛 thread에 공지 미발송 → 사용자 혼란 (어느 thread에서 진행 중인지)
- 사이클 30회 알림에 대해 사용자 무응답인데도 nyongjong이 강제 리프레시 → 자율성 위반

## 검증 명령

```bash
# thread 사이클 누적 측정
node /home/creator/.openclaw/workspace/scripts/openclaw-p216-context-cycle-monitor.js \
  --thread <thread_id>

# 리프레시 키워드 감지
grep -E "thread 세션 리프레시|요약하고 새 세션|컨텍스트 청소" /tmp/openclaw/openclaw-*.log

# 30사이클 알림 발송 이력
grep -E "컨텍스트 누적 30사이클" /tmp/openclaw/openclaw-*.log
```

## 영상 패턴 출처

UsT1-E1Txyo 영상에서 "에이전트 작업이 길어지면 사용자가 명시적으로 세션을 끊고 요약 후 재시작" 패턴 등장. 우리 OpenClaw에선 cron 자동화 대신 마스터 채널 명령 방식으로 구체화 — P-206 cron 신뢰성 위험 회피.

## 관련

- [[pitfall-205-openclaw-project-isolation-thread-per-project]] — thread per project
- [[pitfall-206-openclaw-cron-fire-error-auto-disable-without-fallback]] — cron 위험으로 자동화 보류
- [[pitfall-214-openclaw-autonomous-continuation-prompt-overnight]] — 자율 사이클 + 리프레시 결합
