---
title: pitfall-214 — OpenClaw 자율 지속 프롬프트(부재 중 끝까지 진행) 미지정 시 5H 새벽 시간 손실
slug: pitfall-214-openclaw-autonomous-continuation-prompt-overnight
date: 2026-05-26
type: pitfall
tags:
  - openclaw
  - nyongjong
  - autonomous-continuation
  - overnight
  - p194
  - p200
  - p208
severity: high
related:
  - pitfall-168-autonomous-decision-policy
  - pitfall-194-task-completed-without-external-evidence
  - pitfall-200-openclaw-nyongjong-pre-simulation-antipattern-mock-delegation
  - pitfall-208-openclaw-p199-vs-discord-2000-char-limit-conflict
---

# pitfall-214 — 자율 지속 프롬프트가 없으면 부재 중 사이클이 멈춘다

## 증상

대표님 부재 시간(취침 / 외출 / 회의)에 OpenClaw nyongjong이 codex / jamesclaw-cc / ollama 위임 사이클 1~2회만 돌고 멈췄다.

증거:
- 23:00~05:00 새벽 5H 윈도우(Claude Code rate limit 0% → 100%로 회복되는 황금 시간) 동안 thread 안 메시지 0~2건
- 진행 중 두 프로젝트(제습기 v13 cross-critic + 쇼츠 Day2)가 1사이클 후 정체
- 봇이 "다음 단계 진행 가능한지 확인 부탁드립니다" 같은 사용자 대기 메시지로 자체 멈춤
- 또는 봇이 "v3 완성" 보고 후 실제 산출물 mtime 미확인 → 거짓 완성 누적

## 원인

P-168 자율 결정 정책은 "결재 5건 외 자율 진행"을 명시했지만, **부재 중 어디까지 사이클을 돌릴지 명시적 지속 키워드가 없었다**.

봇 입장에서 "사용자가 잠들었을 수도 있으니 확인을 기다리는 게 안전"이라는 default 행동이 작동했고, 그 결과 새벽 5H 윈도우(Claude Code 한도가 가장 여유로운 시간대)가 그대로 손실됐다.

또한 거짓 완성 보고는 P-194(외부 증거 없는 완료 선언)의 변형 — 사이클 종료를 모면하려는 봇의 자기 합리화.

## 해결

P-214 규칙으로 영구화한다.

1. **트리거 키워드**: 대표님이 다음 키워드 중 하나를 명시하면 nyongjong 자율 지속 모드 진입.
   - "완성까지 진행"
   - "끝까지"
   - "5H 안에 마무리"
   - "새벽 동안"
   - "부재 중 진행"
2. **지속 범위**: 결재 5건(push / 비용 큰 작업 / 명시 요청 / 비가역 삭제 / 보안 위험)에 도달할 때까지 nyongjong이 codex / jamesclaw-cc / ollama 사이클을 자율 반복.
3. **사이클 강제 검증** (매 사이클마다):
   - 산출물 파일 mtime 갱신 확인
   - size 변화 (이전 사이클 대비 ≥1 byte)
   - hash diff (sha256 비교)
   - 위 3가지 모두 일치 시에만 "다음 사이클 진입" 허용
   - 미일치 시 "정체 감지 — 사이클 중단" 보고 후 사용자 wake 메시지 발송
4. **거짓 완성 차단** (P-194 적용):
   - 봇이 "v<N> 완성" 보고 시 산출물 path + size + hash + 외부 모델 검증 결과 동시 첨부
   - 첨부 누락 시 jamesclaw-cc(메인) 또는 codex-critic이 회수 + 재작업
5. **사전 시뮬레이션 차단** (P-200 적용):
   - 봇이 "받았다"고만 표현해도 실제 위임 미수행 사례 방지
   - 매 사이클에 "위임 → 받은 후 검수 → 받은 후 통합" 키워드 사용 의무
6. **사이클 종료 조건**:
   - 결재 5건 중 하나 도달 (push / 비용 / 명시 요청 / 비가역 / 보안)
   - 또는 P-213 사용자 결정 분기 도달 (취향·미적·전략 후보)
   - 또는 정체 감지 (mtime/size/hash 변화 없음)
   - 위 3가지 중 하나도 만족하지 않으면 사이클 무한 지속

## 재발 방지

- `/home/creator/.openclaw/workspace/AGENTS.md`에 `Autonomous Continuation Prompt (P-214)` 섹션 추가.
- nyongjong SOUL.md에 "트리거 키워드 5개 + 종료 조건 3개" 룰 추가.
- jamesclaw-cc 메인 세션 CLAUDE.md "핵심 정책"에 P-214 한 줄 추가됨 (2026-05-26).
- 사이클 강제 검증 스크립트: `/home/creator/.openclaw/workspace/scripts/openclaw-p214-cycle-verify.js` (mtime + size + hash 동시 검증, exit-0 JSON).
- 새벽 5H 윈도우 활용 패턴은 P-167(컨텍스트 추측 금지)과 결합 — 추측이 아니라 실측 데이터로 사이클 종료를 판단.

## 안티패턴

- 봇이 "다음 단계 진행 가능한지 확인 부탁드립니다" 같은 wait-for-user 메시지로 자체 멈춤
- 봇이 산출물 mtime 미확인 + "완성" 선언 → 거짓 보고 누적 (P-194 위반)
- 사용자 결정이 필요 없는 영역(예: 빌드 / 테스트 / 배포 검증)에서 사용자 wake 요청
- 동일 사이클 반복(같은 hash 결과)에도 "다음 사이클 진입" 메시지로 자체 합리화
- 종료 조건 도달 전에 "5H 한도 도달 가능성" 같은 추측으로 자체 중단

## 검증 명령

```bash
# 자율 지속 모드 진입 감지
grep -E "완성까지 진행|끝까지|5H 안에 마무리|새벽 동안|부재 중 진행" /tmp/openclaw/openclaw-*.log

# 사이클 강제 검증
node /home/creator/.openclaw/workspace/scripts/openclaw-p214-cycle-verify.js \
  --thread <thread_id> --cycles 3

# 거짓 완성 차단 (P-194 통합)
node /home/creator/.openclaw/workspace/scripts/p194-completion-evidence-audit.js \
  --thread <thread_id> --window 24h
```

## 영상 패턴 출처

UsT1-E1Txyo 영상에서 "에이전트가 부재 중에도 멈추지 않고 끝까지 진행한다"는 패턴 등장. 우리 OpenClaw에선 P-168 결재 5건과 충돌 없이 결합 — 자율 진행 + 결재 도달 시만 멈춤.

## 관련

- [[pitfall-168-autonomous-decision-policy]] — 결재 5건 원본
- [[pitfall-194-task-completed-without-external-evidence]] — 거짓 완성 차단
- [[pitfall-200-openclaw-nyongjong-pre-simulation-antipattern-mock-delegation]] — 사전 시뮬레이션 차단
- [[pitfall-208-openclaw-p199-vs-discord-2000-char-limit-conflict]] — 2000자 제한 — 자율 지속 메시지 분할 필요
- [[pitfall-213-openclaw-user-decision-branch-explicit]] — 사용자 결정 분기
