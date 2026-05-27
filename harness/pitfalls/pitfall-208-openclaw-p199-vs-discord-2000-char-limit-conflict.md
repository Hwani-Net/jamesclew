---
title: pitfall-208 — OpenClaw P-199 단일 메시지 강제 vs Discord 2000자 제한 충돌 해소
slug: pitfall-208-openclaw-p199-vs-discord-2000-char-limit-conflict
date: 2026-05-26
type: pitfall
tags:
  - openclaw
  - discord
  - 2000-char-limit
  - p199-conflict
  - message-split-policy
  - p208
severity: medium
related:
  - pitfall-194-task-completed-without-external-evidence
  - pitfall-196-openclaw-channel-separation-video-pattern
  - pitfall-198-openclaw-channel-bot-loop-protection-explicit-policy
  - pitfall-199-openclaw-workspace-claude-separate-agents-md-and-session-purge
  - pitfall-200-openclaw-nyongjong-pre-simulation-antipattern-mock-delegation
  - pitfall-201-openclaw-hidden-cron-agentturn-self-driven-evolution
  - pitfall-204-openclaw-codex-critic-perma-persona-content-quality-gate
  - pitfall-205-openclaw-project-isolation-thread-per-project
  - pitfall-206-openclaw-cron-fire-error-auto-disable-without-fallback
  - pitfall-207 (검증 중 발견)
---

# pitfall-208 — P-199 "단일 메시지 강제" vs Discord 2000자 제한 충돌 해소

## 메타헤더

| 항목 | 값 |
|------|-----|
| 발견 시점 | 2026-05-26 (P-207 검증 중 Sonnet 서브에이전트 발견) |
| 핵심 정책 충돌 | P-199 "결과/근거/검증/반환 멘션을 하나의 메시지에 합쳐서" vs Discord 2000자 제한 |
| Discord 제한 | 일반 봇 2000자, Nitro 4000자 — OpenClaw 봇은 Nitro 미적용 |
| OpenClaw 분할 동작 | `send.shared-DTUY7ve1.js`가 2000자 초과 시 자동 분할 |
| 실제 사례 | codex v10 응답 3분할 게시 (msg 1508510364239921243, 1508510365883826258, 1508510368199082125) |
| 발견 트리거 | Sonnet 검증 서브에이전트 fetch 시 동일 봇 3 메시지 연속 발견 |
| 표면 평가 | P-199 위반 외형 (단일 메시지 강제 미준수) |
| 실제 진단 | 2000자 한계로 OpenClaw 자동 분할 → 봇 의도적 분할 아님 |
| 해소 정책 | P-208 — 2000자 초과 시 `[1/N]` 식별 강제 + 분할 허용 5조건 명시 |

## 증상 (관측된 사실만)

### S1. codex v10 응답 3분할 게시 발견

P-207 검증 중 Sonnet 검증 서브에이전트가 thread 안 메시지 fetch:

```bash
curl -H "Authorization: Bot ${TOKEN}" \
  "https://discord.com/api/v10/channels/${THREAD_ID}/messages?limit=10"
```

응답 결과 중 동일 봇 (codex claw) 연속 3 메시지:

- msg `1508510364239921243` (timestamp T)
- msg `1508510365883826258` (timestamp T+0.4s)
- msg `1508510368199082125` (timestamp T+2.7s)

세 메시지 모두 codex claw 발신, 합쳐서 약 5800자 분량의 v10 진화 보고 + critic self-review + nyongjong 반환 mention.

### S2. P-199 외형 위반 — 단일 메시지 강제 미준수

P-199 §"단일 메시지 강제" 규칙:

```
결과/근거/검증/반환 멘션을 반드시 하나의 메시지에 합쳐서 게시할 것.
N분할 시 nyongjong 종합 판정에서 부분 컨텍스트 미스 위험.
```

3분할 게시는 P-199 외형 위반. Sonnet 검증 서브에이전트가 1차 보고에서 "P-199 위반 카운트 1건" 기재.

### S3. OpenClaw 자동 분할 메커니즘 — 봇 의도 아님

분할 원인 진단:

```bash
# OpenClaw send 모듈 grep
grep -n "2000" /home/creator/.openclaw/dist/send.shared-DTUY7ve1.js | head -10

# 출력 (요지):
# const DISCORD_MSG_LIMIT = 2000;
# if (content.length > DISCORD_MSG_LIMIT) {
#   const chunks = splitContent(content, DISCORD_MSG_LIMIT);
#   for (const chunk of chunks) await sendChunk(chunk);
# }
```

→ OpenClaw `send.shared-DTUY7ve1.js`가 2000자 초과 시 자동 분할. **codex 봇이 의도적으로 분할한 것이 아님**.

codex 입장에서는 단일 메시지로 fire했으나, OpenClaw send 모듈이 2000자 한계로 강제 분할.

### S4. P-199 정책상 외형 위반 vs 사실상 인프라 강제

규칙 정합성 분석:

| 차원 | 평가 |
|------|------|
| P-199 정책 외형 | 위반 (3분할 게시) |
| codex 봇 의도 | 미위반 (단일 메시지 fire 시도) |
| OpenClaw 인프라 | 2000자 강제 자동 분할 (수정 불가 외부 코드) |
| nyongjong 수신 측 | 3 메시지 모두 fetch 시 컨텍스트 복원 가능 |

→ **P-199 외형 위반이나 사실상 인프라 강제**. P-199를 그대로 적용하면 봇이 2000자 이상 응답 불가능 — 콘텐츠 품질 저하.

### S5. Discord 메시지 분할 시 식별 누락 위험

OpenClaw 자동 분할은 단순 길이 cutoff이라 `[1/N]` 식별 prefix 추가 안 함. 결과:

- 세 메시지가 단순 시간순으로 게시됨
- nyongjong이 어느 메시지가 첫 부분인지 명확하지 않음
- 부분 fetch 시 컨텍스트 손실 가능

## 진단 과정 (4단계)

### 진단-1. Sonnet 검증 서브에이전트 1차 보고

Sonnet 서브에이전트가 thread `1508392522706194512` 메시지 fetch 후 보고:

```
검증 결과:
- codex v10 응답 발견
- P-199 위반 1건: 3 메시지로 분할 게시 (단일 메시지 강제 미준수)
- 권장: P-199 재강조 + codex 페르소나 단일 메시지 강제 prompt 추가
```

→ Sonnet은 외형만 판정. 분할 원인 진단 없음.

### 진단-2. OpenClaw send 모듈 직접 grep

```bash
grep -rn "DISCORD_MSG_LIMIT\|2000" /home/creator/.openclaw/dist/*.js | head -20
```

OpenClaw send 모듈에서 2000자 자동 분할 메커니즘 확인. 봇 측 의도가 아닌 인프라 강제임을 확정.

### 진단-3. codex 응답 합쳐서 본문 검증

3 메시지 본문 합쳐서 분석:

- msg 1 (약 1950자): v10 진화 보고 + 변경 사항 요약
- msg 2 (약 1900자): [CRITIC] self-review + 블로커 도출
- msg 3 (약 950자): nyongjong 반환 mention + 다음 step 제안

합쳐서 P-199 의도 (결과 + 근거 + 검증 + 반환 mention) 모두 포함. **콘텐츠 측면에서는 P-199 준수**.

→ 외형 위반 vs 실질 준수의 갭 확정.

### 진단-4. 해소 정책 P-208 설계

P-199를 무력화하지 않으면서 2000자 한계 수용:

- 2000자 이내: P-199 그대로 (단일 메시지 강제 유지)
- 2000자 초과: 분할 허용 + 식별 prefix 강제 + 시간 차 5초 이내 강제

## 진짜 메커니즘 (Root Cause)

### M1. Discord 일반 봇 2000자 제한

Discord API 메시지 본문 한계 2000자 (Nitro 4000자). OpenClaw 봇은 Nitro 미적용이라 2000자 cutoff.

### M2. OpenClaw send 모듈 자동 분할

`send.shared-DTUY7ve1.js`가 2000자 초과 시 단순 cutoff 분할. 식별 prefix 추가 안 함, 시간 차 0초 (asyncio.gather 시도).

### M3. P-199 단일 메시지 강제의 의도

P-199는 "결과 + 근거 + 검증 + 반환 mention"이 컨텍스트로 묶여서 nyongjong이 한 번 fetch로 종합 판정하도록 의도. 분할 시 부분 컨텍스트만 fetch될 위험 회피.

### M4. P-199와 2000자 제한의 본질적 충돌

P-199는 단일 메시지 강제, Discord는 2000자 제한. 두 규칙의 곱집합 → **메시지당 2000자 이내** 강제로 귀결. 그러나 진화 보고는 평균 3000~5000자 → P-199 그대로 적용 시 콘텐츠 손실.

### M5. 외형 vs 실질 정합성의 갭

P-199 외형 위반과 실질 준수가 동시 발생하는 케이스는 정책 설계 시 사전 고려되지 않음. 외형 위반만 보고 P-199 재강조하면 봇이 콘텐츠를 잘라야 함 — 진화 보고 품질 저하.

## 옵션 비교

### A안 — P-199 그대로 + 2000자 이내 강제

봇이 응답을 2000자 이내로 자체 truncate.

**거부 사유**: 진화 보고/[CRITIC] self-review/반환 mention 합쳐서 3000~5000자가 평균 — 콘텐츠 손실 직격.

### B안 — Discord Nitro 적용 (4000자 한계)

OpenClaw 4봇 모두 Nitro 적용 시 4000자 한계.

**거부 사유**: Nitro 구독료 ($10/month × 4 = $40/month) 부담. 콘텐츠가 5000자+이면 여전히 충돌.

### C안 — OpenClaw send 모듈 패치 (식별 prefix 추가)

`send.shared-DTUY7ve1.js`를 패치해 분할 시 `[1/N]` prefix 자동 추가.

**거부 사유**: OpenClaw upstream 코드 수정 → 업데이트 시 손실 위험. 자체 fork 유지 부담.

### D안 (선택) — P-208 정책 신설 (분할 허용 5조건 + 식별 강제)

P-199를 2000자 이내에 한정. 2000자 초과 시 분할 허용 + 식별 prefix 강제 + 5조건 명시.

**선택 사유**:
- P-199 의도 (컨텍스트 묶음) 유지
- Discord 제한 수용
- nyongjong 수신 측 정책으로 부분 fetch 위험 해소

## 적용 이력

### 적용-1. workspace-codex/AGENTS.md §"P-208" 추가 (+1001 bytes)

`/home/creator/.openclaw/workspace-codex/AGENTS.md` 끝에:

```markdown
## P-208: P-199 vs Discord 2000자 충돌 해소

### 분할 허용 5조건

P-199 단일 메시지 강제를 2000자 이내에만 적용. 2000자 초과 시 다음 5조건 충족 분할 허용:

1. **동일 thread/채널 내 연속 게시** (시간 차 5초 이내)
2. **메시지 첫 줄에 `[1/N]` 분할 식별** (예: `[1/3] v10 진화 보고:`)
3. **최종 mention은 마지막 N/N에만** (`@nyongjong` 등 반환 mention은 마지막 분할에)
4. **검증/grep/짧은 코드는 별도 메시지 가능** (분할 카운트와 무관)
5. **수신자(nyongjong)는 N개 모두 fetch 후 합쳐서 판정** (부분 fetch 금지)

### Anti-pattern (금지)

- 2000자 이내인데 일부러 분할 (P-199 위반)
- 분할 식별 prefix 누락 (`[1/N]` 없이 분할)
- 분할마다 mention 인플레이션 (`@nyongjong` 매 분할마다 게시)
- 분할 간 시간 차 5초 초과 (다른 메시지 끼어들 위험)
```

### 적용-2. workspace-claude/AGENTS.md §"P-208" 추가 (+1001 bytes)

`/home/creator/.openclaw/workspace-claude/AGENTS.md` 끝에 동일 내용 추가 (jamesclaw-cc 봇 측 동일 규칙).

### 적용-3. nyongjong 수신 정책 강화

nyongjong이 thread 안 메시지 fetch 시:

- `[1/N]` prefix 발견 시 N 메시지 모두 fetch 후 합쳐서 판정
- `[1/N]` 보고 누락 시 즉시 위반 판정 (P-208 위반)
- 분할 메시지 부분 컨텍스트만 fetch 후 판정 금지

## 재발 방지 (체크리스트)

### 봇 응답 생성 시

- [ ] 응답 길이 2000자 이내 → 단일 메시지 게시 (P-199 강제)
- [ ] 2000자 초과 → 분할 허용 + `[1/N]` prefix 강제
- [ ] 분할 시 시간 차 5초 이내
- [ ] 최종 mention은 마지막 분할에만
- [ ] OpenClaw 자동 분할 발생 시 prefix 누락 → 봇이 prefix 강제 추가

### nyongjong 수신 시

- [ ] thread 메시지 fetch 시 `[1/N]` prefix 감지
- [ ] N 메시지 모두 fetch 후 합쳐서 판정
- [ ] 부분 fetch 후 판정 금지
- [ ] 분할 메시지 보고 누락 시 P-208 위반 판정

### Sonnet 검증 서브에이전트

- [ ] 동일 봇 연속 N 메시지 발견 시 P-208 외형 분할 평가
- [ ] OpenClaw 자동 분할 vs 봇 의도 분할 구분
- [ ] `[1/N]` prefix 존재/누락 검증

## 검증 명령

### Thread 메시지 분할 검증

```bash
curl -H "Authorization: Bot ${TOKEN}" \
  "https://discord.com/api/v10/channels/${THREAD_ID}/messages?limit=10" \
  | python3 -c "
import json, sys
msgs = json.load(sys.stdin)
for m in msgs:
    print(f\"{m['author']['username']}: {m['content'][:50]}... ({len(m['content'])} chars)\")
"

# 출력: 동일 봇 연속 N 메시지 + 각각 길이
# 2000자에 근접한 메시지 + [1/N] prefix 존재 확인
```

### AGENTS.md §"P-208" 존재 확인

```bash
grep -n "## P-208" /home/creator/.openclaw/workspace-codex/AGENTS.md
grep -n "## P-208" /home/creator/.openclaw/workspace-claude/AGENTS.md

# 출력: 2개 모두 1+ hit
```

## 향후 진화 트리거

본 PITFALL이 다음 조건 만족 시 자동 진화:

1. P-208 적용 후 분할 prefix 누락 0건 30일
2. nyongjong 부분 fetch 위반 0건 30일
3. 2000자 이내 응답 P-199 단일 메시지 강제 준수율 95%+

위 3개 충족 시 본 PITFALL을 distilled tier 승격.

## Backlinks

- **P-194** task completed without external evidence — 분할 메시지 부분 fetch 후 판정 금지가 P-194 재강화
- **P-196** channel separation video pattern — 7채널 + thread 안에서 분할 정책 적용
- **P-198** channel bot loop protection explicit policy — 분할 메시지도 봇 trigger 단일 메시지 대우
- **P-199** workspace claude separate AGENTS.md and session purge — 본 PITFALL이 P-199 단일 메시지 강제 정책의 예외 정의
- **P-200** nyongjong pre-simulation antipattern mock delegation — 분할 메시지 "받은 후" 키워드는 마지막 분할에만 적용
- **P-201** hidden cron agentTurn self-driven evolution — 분할 메시지 stream trigger에서도 동일 적용
- **P-204** codex-critic 페르소나 영구 통합 — [CRITIC] self-review가 자주 2000자 초과 → P-208 적용 빈번
- **P-205** project isolation thread-per-project — thread 안에서 분할 메시지 발생 시 P-208 적용
- **P-206** cron fire error auto disable without fallback — 메시지 stream trigger 분할 시 nyongjong 수신 정책 강화
- **P-207** (검증 중 발견) — 본 PITFALL이 P-207 검증 중 Sonnet 서브에이전트 발견

## 한 줄 요약

Discord 2000자 제한과 OpenClaw send 자동 분할 메커니즘 때문에 P-199 "단일 메시지 강제"가 외형 위반될 수밖에 없으므로, 2000자 이내는 P-199 그대로, 2000자 초과 시 `[1/N]` 식별 prefix + 5초 이내 연속 게시 + 최종 mention 마지막 분할 + nyongjong 수신 측 N개 fetch 합산의 5조건 분할을 허용하라.
