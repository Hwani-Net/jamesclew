---
title: pitfall-205 — OpenClaw 다중 프로젝트 컨텍스트 격리 부재 → Thread-per-Project 강제
slug: pitfall-205-openclaw-project-isolation-thread-per-project
date: 2026-05-25
type: pitfall
tags:
  - openclaw
  - project-isolation
  - discord-thread
  - context-separation
  - video-pattern-33-46
  - autonomous-orchestration
  - p205
severity: high
related:
  - pitfall-191-openclaw-codex-cannot-fire-discord-mentions
  - pitfall-194-task-completed-without-external-evidence
  - pitfall-196-openclaw-channel-separation-video-pattern
  - pitfall-198-openclaw-channel-bot-loop-protection-explicit-policy
  - pitfall-199-openclaw-workspace-claude-separate-agents-md-and-session-purge
  - pitfall-200-openclaw-nyongjong-pre-simulation-antipattern-mock-delegation
  - pitfall-201-openclaw-hidden-cron-agentturn-self-driven-evolution
  - pitfall-204-openclaw-codex-critic-perma-persona-content-quality-gate
  - pitfall-206-openclaw-cron-fire-error-auto-disable-without-fallback
---

# pitfall-205 — 다중 프로젝트 컨텍스트 격리 부재 + Discord Thread-per-Project 강제

## 메타헤더

| 항목 | 값 |
|------|-----|
| 발생 채널 | OpenClaw 4봇 환경 (nyongjong + jamesclaw-cc + codex claw + ollama claw) |
| 사건 일시 | 2026-05-25 (Day1 제습기 비교 진행 중 대표님 새 프로젝트 의문 제기) |
| 트리거 메시지 | 대표님 — "다른 프로젝트(유튜브 쇼츠) 시작하면 #작업-요청에서 컨텍스트 섞이는가?" |
| 기존 구조 | 7채널 (#공지사항/작업-요청/작업-진행중/작업-완료/리뷰-요청/리뷰-완료/자료실) |
| 영상 원본 의도 | UsT1-E1Txyo 33:46 다이어그램 = 채널 단위가 아니라 **thread 단위** 프로젝트 격리 |
| 실제 운영 | thread 명목만 — 모든 작업 메인 채널에서 혼재 (P-201 검증 시 확인) |
| 옵션 채택 | 옵션 A (#작업-진행중에 프로젝트별 thread 자동 생성, 영상 33:46 의도 100%) |
| 검증 thread ID | `1508475922599248012` (가짜 유튜브 쇼츠 프로젝트, 실제 Discord API 호출 성공) |
| 기존 thread ID | `1508392522706194512` (제습기 비교 thread, 컨텍스트 격리 확인) |

## 증상 (관측된 사실만)

### S1. 7채널 구조에서 다중 프로젝트 진행 시 컨텍스트 혼재 우려

대표님 직접 질문 (2026-05-25):

```
다른 프로젝트 — 예를 들어 유튜브 쇼츠 1편 콘셉트 기획 — 을 시작하면
#작업-요청 채널에 기존 제습기 v6 진행 메시지와 새 유튜브 메시지가
시간순으로 섞여서 nyongjong이 어느 프로젝트 컨텍스트로 응답할지 혼란하지 않는가?
```

P-196 7채널 구조는 작업 단계 (요청/진행중/완료/리뷰) 분리이지 **프로젝트 분리**가 아님. 다중 프로젝트 진행 시 채널 내부에서 메시지 시간순 혼재 → nyongjong이 직전 메시지 fetch만으로는 어느 프로젝트 응답인지 판정 불가.

### S2. 영상 33:46 다이어그램 재검토 — thread 단위 격리

UsT1-E1Txyo 영상 33:46 다이어그램 분석:

- 메인 채널 = #작업-진행중 (단일)
- 각 프로젝트마다 thread 1개 생성
- 프로젝트 N개 = thread N개 (메인 채널 1개)
- 모든 위임/작업/검수가 thread 안에서만 진행

→ **채널 단위가 아니라 thread 단위 프로젝트 격리**가 영상 원본 의도.

### S3. 우리 환경에서 thread 명목만, 실제 사용 0

P-201 (hidden cron agentTurn) 검증 시점에 다음 사실 확인:

```bash
# Discord API로 #작업-진행중 채널의 active thread 조회
curl -H "Authorization: Bot ${TOKEN}" \
  "https://discord.com/api/v10/channels/${PROGRESS_CHANNEL_ID}/threads/active"
```

응답: thread 0개 또는 archived thread만 존재. **활성 thread 0개**.

`/tmp/openclaw/openclaw-2026-05-25.log` grep:

```bash
grep -i "thread" /tmp/openclaw/openclaw-2026-05-25.log | head -20
```

결과: thread 관련 로그 0건 (메시지 모두 메인 채널 ID로만 fire/fetch).

→ thread 명목상 존재하나 실제 0건 사용. 영상 의도 (thread-per-project)에서 이탈.

### S4. nyongjong "직전 메시지 컨텍스트"만으로 프로젝트 판정 불가

기존 nyongjong 위임 로직:

```
1. #작업-요청 메시지 fetch
2. 직전 N개 메시지 stream 분석
3. defaultTo 봇 매핑으로 위임
```

다중 프로젝트 시 직전 N개 메시지에 제습기 v6 + 유튜브 쇼츠 콘셉트 메시지가 혼재되면 위임 컨텍스트 오염. codex claw에 유튜브 콘셉트 메시지를 fire하면서 직전 컨텍스트에 제습기 v5 본문이 포함되면 → 잘못된 fallback 동작 발생 가능.

### S5. 4가지 옵션 비교 — 옵션 A만 영상 33:46 의도 100% 충족

대표님 질문에 대한 4가지 해법 검토:

- **옵션 A**: #작업-진행중에 프로젝트별 thread 자동 생성 (영상 33:46 의도 100%) ← 채택
- **옵션 B**: 프로젝트별 채널 N개 추가 (영상 7채널 구조 무너짐)
- **옵션 C**: 카테고리 + 채널 분리 (가장 무거움, 봇 token/allowlist 부담 폭증)
- **옵션 D**: 단일 채널 + 라벨/태그 (라벨 누락 시 혼재 재발)

옵션 A 선택.

## 진단 과정 (5단계)

### 진단-1. 대표님 질문의 컨텍스트 추출

질문 원문:

```
다른 프로젝트 시작하면 #작업-요청에서 컨텍스트 섞이는가?
```

핵심 어휘:
- "다른 프로젝트" = 다중 프로젝트 동시 진행
- "#작업-요청" = 7채널 중 entry point
- "컨텍스트 섞이는가" = 메시지 시간순 혼재 우려

→ **다중 프로젝트 격리 메커니즘 부재가 명시 우려 사항** 확정.

### 진단-2. 영상 33:46 다이어그램 재검토

영상 원본 (UsT1-E1Txyo) 33:46 시점 다이어그램 화면 캡처 분석:

- 화면 좌측: 7채널 구조 (P-196에 적용됨)
- 화면 우측: #작업-진행중 채널 내부 thread 트리 (project-A-thread, project-B-thread, ...)
- 화살표: 각 project thread 안에서 위임/작업/검수 흐름이 thread-local로 완결

→ 영상 원본 의도는 7채널 + **thread-per-project** 결합. P-196 적용 시점에 thread 부분 누락.

### 진단-3. Discord API로 thread 존재/사용 검증

```bash
# Discord API thread list
curl -H "Authorization: Bot ${TOKEN}" \
  "https://discord.com/api/v10/channels/${PROGRESS_CHANNEL_ID}/threads/active"

# 결과: {"threads":[],"members":[]}
```

활성 thread 0개. archived thread 조회:

```bash
curl -H "Authorization: Bot ${TOKEN}" \
  "https://discord.com/api/v10/channels/${PROGRESS_CHANNEL_ID}/threads/archived/public"

# 결과: {"threads":[],"members":[],"has_more":false}
```

archived thread도 0개. → **thread 사용 이력 전무**.

### 진단-4. 4 옵션 비교

| 기준 | 옵션 A (thread-per-project) | 옵션 B (채널 N개) | 옵션 C (카테고리+채널) | 옵션 D (라벨/태그) |
|------|------------------------------|--------------------|--------------------------|---------------------|
| 영상 33:46 의도 일치 | 100% | 0% (7채널 구조 무너짐) | 0% | 0% |
| 프로젝트 격리 강도 | 강 (thread = scope) | 강 (채널 = scope) | 매우 강 | 약 (라벨 누락 위험) |
| 신규 인프라 부담 | nyongjong thread 생성 권한만 | 채널 N개 + allowlist 갱신 | 카테고리+채널 다수 | 라벨 메커니즘 신설 |
| Discord API 부담 | thread API (이미 권한 보유) | 채널 생성 권한 + N개 channel ID 관리 | 카테고리 권한 추가 | 라벨 봇 추가 |
| #공지사항 가시성 | thread 인덱스로 노출 | 채널 사이드바 자동 노출 | 카테고리로 그룹화 | 단일 채널 그대로 |

옵션 A 채택.

### 진단-5. 옵션 A 시범 구현 + 검증

가짜 새 프로젝트로 시범 테스트:

```bash
# nyongjong이 #작업-진행중에 thread 생성
curl -X POST -H "Authorization: Bot ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "youtube-shorts-1ep-concept-2026-05-25",
    "type": 11,
    "auto_archive_duration": 10080
  }' \
  "https://discord.com/api/v10/channels/${PROGRESS_CHANNEL_ID}/threads"
```

응답: thread ID `1508475922599248012` 생성 성공.

기존 제습기 thread (P-204 진화 진행 중):
- thread ID `1508392522706194512` (rainy-day1-dehumidifier-2026-05-25)

두 thread 병렬 진행 검증:
- nyongjong → codex (제습기 v6 위임) — thread `1508392522706194512` 안에서만
- nyongjong → codex (유튜브 콘셉트 v0 위임) — thread `1508475922599248012` 안에서만

→ **두 프로젝트 컨텍스트 완전 격리 확인**. 옵션 A 동작 검증 완료.

## 진짜 메커니즘 (Root Cause)

### M1. P-196 적용 시점에 thread 누락

P-196 (channel separation video pattern) 적용 시 7채널 구조만 도입, thread-per-project 부분이 누락됨. 영상 33:46 다이어그램의 **메인 채널 + thread 결합 구조** 절반만 구현.

### M2. nyongjong 위임 로직이 단일 채널 stream 가정

nyongjong defaultTo 매핑 + fetch_messages 로직은 모두 단일 채널 stream을 가정. 다중 프로젝트 메시지가 시간순 혼재될 가능성을 사전 고려하지 않음.

### M3. Discord thread 메커니즘 미활용

Discord API thread 생성 권한은 봇에 부여되어 있으나 (allowlist 7채널 모두 read+write+thread 권한), 실제 thread 생성/사용 0건. 메커니즘 자체가 휴면 상태.

### M4. 메인 채널 메시지 시간순 정렬의 한계

#작업-요청 채널은 시간순 정렬이 default. 다중 프로젝트 메시지가 시간순으로 도착하면 nyongjong이 메시지 발신자/내용 키워드만으로 프로젝트를 분리해야 함. 라벨/태그 부재 시 분리 정확도 낮음.

### M5. thread 가시성 부족 — 평상시 사이드바에 미노출

Discord thread는 활성 상태일 때만 채널 사이드바에 일시 표시. archived 또는 비활성 thread는 사이드바에서 사라짐. → 대표님이 진행 중 프로젝트를 한눈에 보기 어려움.

### M6. 영상 33:46 의도의 핵심은 scope localization

thread = 프로젝트 scope. 위임/작업/검수가 모두 thread 안에서 완결되면:
- 컨텍스트 fetch가 thread 안으로 제한됨 (혼재 0)
- 다른 프로젝트와 무관한 메시지 stream
- 프로젝트 완료 시 thread archive로 자동 정리

이것이 영상 원본 의도의 핵심 가치.

## 옵션 비교 (옵션 A 선택 근거 확장)

### A안 (선택) — 옵션 A: #작업-진행중에 프로젝트별 thread 자동 생성

영상 33:46 의도 100% 적용. nyongjong이 새 프로젝트 자연어 메시지 도착 시 자율로 thread 생성.

**선택 사유**:
- 영상 원본 의도 정확 구현
- 신규 인프라 부담 최소 (Discord thread API 이미 활성)
- nyongjong thread 생성 권한만 추가 (다른 봇은 그대로)
- 프로젝트 완료 시 thread archive로 자동 정리

### B안 — 옵션 B: 프로젝트별 채널 N개 추가

새 프로젝트마다 #project-N 채널 추가.

**거부 사유**:
- P-196 7채널 구조 무너짐 (작업 단계 분리 의도 손실)
- 채널 N개마다 7채널 단계 분리 재구현 필요 (7N 채널)
- allowlist 갱신 부담 폭증

### C안 — 옵션 C: 카테고리 + 채널 분리

Discord 카테고리 (project-A, project-B) + 각 카테고리에 7채널 sub-set.

**거부 사유**:
- 가장 무거운 구조 (카테고리 N개 × 7채널 = 7N 채널)
- 봇 token/allowlist 부담 폭증
- 카테고리 권한 추가 필요

### D안 — 옵션 D: 단일 채널 + 라벨/태그

기존 7채널 그대로 + 메시지에 `[project-A]` 라벨 prefix.

**거부 사유**:
- 라벨 누락 시 혼재 재발 (사람/봇 모두 라벨 강제 보장 어려움)
- nyongjong 위임 로직에 라벨 파싱 추가 필요
- 라벨 봇 추가 또는 매 위임 시 prefix 강제 → 운영 부담

## 적용 이력

### 적용-1. workspace/AGENTS.md §"Project Isolation (P-205)" 추가

`/home/creator/.openclaw/workspace/AGENTS.md` 끝에 다음 섹션 추가:

```markdown
## Project Isolation (P-205)

### Thread-per-Project 강제

- 새 프로젝트 자연어 메시지 도착 시 nyongjong이 자율로 #작업-진행중에 thread 생성
- thread 이름: `<프로젝트-슬러그>-YYYY-MM-DD` (예: `youtube-shorts-1ep-concept-2026-05-25`)
- `auto_archive_duration: 10080` (7일) 명시 — 활동 중 카운터 자동 reset
- 모든 위임/작업/검수가 thread 안에서만 진행
- 완료 시 #작업-완료 + #자료실 + #작업-요청 답신 (thread 외부 알림)

### 새 프로젝트 감지 트리거

- #작업-요청에 자연어 메시지 도착
- 직전 N개 메시지 stream에 동일 프로젝트 키워드 0건
- 메시지 본문에 새 프로젝트 슬러그 (`/유튜브`, `/블로그`, `/제습기` 등) 명시
- 위 3개 중 1+ 만족 시 nyongjong이 thread 생성

### Thread 인덱스 관리 (P-205-A 보강)

- Discord thread는 평상시 사이드바에 안 보임 (대표님 지적)
- `#공지사항` 채널에 "진행 중 프로젝트 인덱스" 메시지 (대표님 수동 pin 1회)
- nyongjong이 thread 생성/완료 시 인덱스 메시지 자율 갱신 (메시지 관리 권한 부여됨)
- 인덱스 메시지 형식:
  ```
  ## 진행 중 프로젝트 (2026-05-25 기준)
  - [제습기 비교 Day1] thread:1508392522706194512 (v6 진화 중)
  - [유튜브 쇼츠 1편 콘셉트] thread:1508475922599248012 (v0 기획 중)
  ```
```

### 적용-2. workspace-claude/AGENTS.md §"Project Isolation — Thread context (P-205)" 추가

`/home/creator/.openclaw/workspace-claude/AGENTS.md` 끝에 jamesclaw-cc 측 thread context 인식 추가:

```markdown
## Project Isolation — Thread context (P-205)

### Thread-local fetch 강제

- 위임 메시지 수신 시 thread ID 확인 (메시지 메타 `channel_id` ≠ `parent_id`)
- fetch_messages 시 thread ID로만 fetch (parent channel 메시지 fetch 금지)
- thread 외부 메시지를 컨텍스트로 포함하지 말 것

### 답신 위치

- 작업 결과는 thread 안에 답신 (parent channel 답신 금지)
- thread 완료 시점에 nyongjong이 #작업-완료에 thread 링크 + 요약 게시
```

### 적용-3. workspace-codex/AGENTS.md §"Project Isolation — Thread context (P-205)" 추가

`/home/creator/.openclaw/workspace-codex/AGENTS.md` 끝에 codex claw 측 동일 규칙 추가 (위와 동일 내용).

### 적용-4. 가짜 새 프로젝트 시범 검증

```bash
# 1. nyongjong이 가짜 새 프로젝트 메시지 수신
echo "유튜브 쇼츠 1편 콘셉트 기획해줘" | nyongjong fire

# 2. nyongjong 자율로 thread 생성
curl -X POST ... → thread ID 1508475922599248012

# 3. codex claw에 thread 안에서 위임
nyongjong → codex (thread 1508475922599248012): "콘셉트 v0 생성"

# 4. 기존 제습기 thread (1508392522706194512)와 컨텍스트 완전 격리 확인
fetch_messages(thread:1508475922599248012) → 유튜브 메시지만
fetch_messages(thread:1508392522706194512) → 제습기 메시지만
```

검증 결과:
- thread `1508475922599248012` 생성 성공 (Discord API HTTP 201)
- 두 프로젝트 thread 컨텍스트 완전 격리
- nyongjong이 thread별 fetch_messages 정상 동작
- 병렬 진행 가능 입증

### 적용-5. #공지사항 인덱스 메시지 생성

```bash
# nyongjong이 #공지사항 채널에 인덱스 메시지 게시
nyongjong → #공지사항: "## 진행 중 프로젝트 인덱스 ..."

# 대표님이 수동 pin (1회)
# 향후 nyongjong이 thread 생성/완료 시 메시지 관리 권한으로 자율 갱신
```

## 재발 방지 (체크리스트)

### 새 프로젝트 시작 시

- [ ] nyongjong이 #작업-요청 메시지에서 새 프로젝트 키워드 감지
- [ ] 직전 N개 메시지 stream에 동일 프로젝트 키워드 0건 확인
- [ ] #작업-진행중에 thread 자동 생성 (이름: `<슬러그>-YYYY-MM-DD`)
- [ ] `auto_archive_duration: 10080` (7일) 명시
- [ ] thread ID를 #공지사항 인덱스 메시지에 추가

### 위임/작업/검수 시

- [ ] thread ID 확인 → 모든 메시지 thread 안에서만
- [ ] fetch_messages는 thread ID로만 (parent channel 금지)
- [ ] 답신/결과도 thread 안에 게시
- [ ] thread 완료 시점에 #작업-완료에 thread 링크 + 요약 게시

### 가시성 관리

- [ ] #공지사항 인덱스 메시지 nyongjong 자율 갱신
- [ ] thread 7일 archive 전 활동 시 카운터 reset 확인
- [ ] 프로젝트 완료 시 thread archive + 인덱스 메시지에서 제거

### 다중 프로젝트 검증

- [ ] 2+ 프로젝트 동시 진행 시 각 thread fetch_messages 격리 확인
- [ ] nyongjong defaultTo 매핑이 thread ID 기반 동작 검증

## 검증 명령

### Thread 생성/사용 검증

```bash
# Active thread 조회
curl -H "Authorization: Bot ${TOKEN}" \
  "https://discord.com/api/v10/channels/${PROGRESS_CHANNEL_ID}/threads/active"

# 출력: {"threads":[{...thread objects...}], "members":[...]}
# 활성 프로젝트 수 = thread 수
```

### Thread-local fetch 검증

```bash
# 특정 thread의 메시지만 fetch
curl -H "Authorization: Bot ${TOKEN}" \
  "https://discord.com/api/v10/channels/${THREAD_ID}/messages?limit=50"

# 출력: thread 안 메시지만 (parent channel 메시지 제외)
```

### #공지사항 인덱스 메시지 존재 확인

```bash
curl -H "Authorization: Bot ${TOKEN}" \
  "https://discord.com/api/v10/channels/${ANNOUNCE_CHANNEL_ID}/messages/pins"

# 출력: 인덱스 메시지 1개 (대표님 pin 후)
```

### AGENTS.md §"Project Isolation" 존재 확인

```bash
grep -n "## Project Isolation" /home/creator/.openclaw/workspace/AGENTS.md
grep -n "## Project Isolation" /home/creator/.openclaw/workspace-claude/AGENTS.md
grep -n "## Project Isolation" /home/creator/.openclaw/workspace-codex/AGENTS.md

# 출력: 3개 모두 1+ hit
```

## 향후 진화 트리거

본 PITFALL이 다음 조건 만족 시 자동 진화 (Distilled tier 승격 검토):

1. P-205 적용 후 다중 프로젝트 (2+) 동시 진행 30일 무사고 (컨텍스트 혼재 0건)
2. nyongjong 자율 thread 생성 누락률 5% 미만 (10회 새 프로젝트 중 9회 이상 자율 생성)
3. #공지사항 인덱스 메시지 갱신 누락 0건 30일

위 3개 모두 충족 시 본 PITFALL을 `$OBSIDIAN_VAULT/05-wiki/distilled/openclaw-thread-per-project-isolation.md`로 distill.

## Backlinks (자기 참조 네트워크)

- **P-191** OpenClaw codex가 Discord mention을 직접 fire 못 함 — codex 봇 환경 제약 (thread fire는 fallback 가능)
- **P-194** task completed without external evidence — thread 생성 보고 시 thread ID 첨부 강제 (P-194 재강화)
- **P-196** channel separation video pattern (7채널) — 본 PITFALL이 보완 (영상 33:46 thread 부분 누락 보완)
- **P-198** channel bot loop protection explicit policy — thread 안에서도 봇 trigger 메커니즘 유지
- **P-199** workspace claude separate AGENTS.md and session purge — AGENTS.md 분기 운영 패턴, 본 PITFALL §"Project Isolation" 추가의 토대
- **P-200** nyongjong pre-simulation antipattern mock delegation — thread 안 위임 시 "받은 후" 키워드 유지
- **P-201** hidden cron agentTurn self-driven evolution — thread 명목 0 사용 발견 사례
- **P-204** codex-critic 페르소나 영구 통합 — 5단계 진화 흐름이 thread 안에서 격리 운영됨
- **P-206** cron fire error auto disable without fallback — thread 안에서도 메시지 stream trigger 채택

## 자기 참조 (P-205가 P-205를 위반하지 않도록)

본 PITFALL 작성 자체도 thread-per-project 원칙을 따라야 함:

1. 본 PITFALL 작성은 단일 프로젝트 (PITFALL 기록) — thread 1개 (또는 thread 없이 메인 채널)
2. 다른 프로젝트 (제습기 v6, 유튜브 콘셉트)와 컨텍스트 격리됨
3. 향후 PITFALL 작성 작업이 새 프로젝트로 시작될 경우 #작업-진행중에 thread 생성 후 진행

## 한 줄 요약

OpenClaw 7채널 구조는 작업 단계 분리이지 프로젝트 분리가 아니므로, 영상 33:46 다이어그램의 thread-per-project 원칙을 적용하여 nyongjong이 새 프로젝트 자연어 메시지 도착 시 #작업-진행중에 thread를 자율 생성하고 모든 위임/작업/검수를 thread 안에서만 진행하라.
