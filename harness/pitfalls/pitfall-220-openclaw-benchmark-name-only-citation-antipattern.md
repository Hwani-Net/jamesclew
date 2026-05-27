---
title: pitfall-220 — OpenClaw 벤치마킹 명목만 차용 안티패턴 ("Wirecutter 수준" 키워드 차용 → 구조 학습 누락)
slug: pitfall-220-openclaw-benchmark-name-only-citation-antipattern
date: 2026-05-26
type: pitfall
tags:
  - openclaw
  - benchmark
  - wirecutter
  - false-completion
  - p194-variant
  - p204-limitation
  - cross-family-critic-failure
  - structure-vs-text
  - tavily-fetch-required
  - p220
severity: critical
related:
  - pitfall-194-task-completed-without-external-evidence
  - pitfall-204-openclaw-codex-critic-perma-persona-content-quality-gate
  - pitfall-218-claude-code-sub-agent-wsl2-path-explicit-required
  - pitfall-219-openclaw-approval-channel-separation
---

# pitfall-220 — 벤치마킹 명목만 차용 안티패턴 (구조 학습 없이 "○○ 수준" 키워드만 인용)

## 메타헤더

| 항목 | 값 |
|------|-----|
| 발생 채널 | OpenClaw 4봇 환경 (nyongjong + jamesclaw-cc + codex claw + ollama claw) |
| 사건 일시 | 2026-05-26 (장마철 가전 비교 블로그 7일 자율 운영 Day-7 마지막 검증) |
| 핵심 산출물 | 장마철 가전 비교 블로그 5편 (v14 — 최종본) |
| 1차 판정 | 3봇 critic (codex-main + codex-critic + ollama) 모두 "발행 가능" 통과 |
| 실제 품질 | Wirecutter "수준" 명목만 차용, 실제 구조 학습 0 — 콘셉트부터 다름 |
| 발견 트리거 | 대표님 직접 질문 (2026-05-26 10:00 KST): "어떤 사이트 벤치마킹? 제품사진 위에서 보여주고 다음부터는 모델명으로만 비교? 사진 누르면 제품 링크 연결 X?" |
| 검증 방법 | researcher Sonnet → Tavily fetch (`tavily-extract https://wirecutter.com/.../best-dehumidifiers/`) → v14 구조 항목별 대조 |
| 처리 | v15 재작성 결정 + P-220 영구화 + P-221 (벤치마크 fetch 게이트) 후속 작성 예고 |

---

## 증상 (관측된 사실만)

### S1. 7일 진화 + 3봇 critic 통과 → "Wirecutter 수준" 자임

**작업 흐름** (Day-1 ~ Day-7):

```
Day-1: 제습기 5종 v1 → codex-critic FAIL → v2 보강
Day-2: 가습기 5종 v3 → cross-family critic 통과
...
Day-6: v13 통합 보강 (P-204 Wirecutter 7대 기준 검증 통과)
Day-7: v14 최종 — 3봇 critic 일치 "발행 가능"
```

**v14 본문 자임 문구**:
```
"본 비교는 Wirecutter 수준의 데이터 깊이를 목표로
정량 비교 / 명시 승자 / 시나리오 정답 / 가격 / 랭킹 / 출처 / 장단점
7대 기준을 모두 충족하도록 재구성하였다."
```

3봇 critic 모두 통과 판정:
- codex-main: "Wirecutter 7대 기준 PASS. 발행 가능"
- codex-critic (공격적 페르소나): "정량 표 + 승자 + 시나리오 모두 명시. 통과"
- ollama: "Publishable: Yes. 데이터 일관성 OK"

### S2. 대표님 질문 (2026-05-26 10:00 KST)

> "어떤 사이트 벤치마킹? 제품사진 위에서 보여주고 다음부터는 모델명으로만 비교?
> 사진 누르면 제품 링크 연결 X?"

→ **3봇 critic 통과 직후 대표님 1개 질문으로 즉시 구조 격차 노출**.

### S3. researcher Sonnet → Tavily 실제 Wirecutter fetch 결과

10:10 nyongjong이 researcher Sonnet에 위임. researcher가 Tavily로 Wirecutter 실제 페이지 fetch:

```bash
tavily-extract https://www.nytimes.com/wirecutter/reviews/best-dehumidifier/
tavily-extract https://www.nytimes.com/wirecutter/reviews/best-air-purifier/
```

**Wirecutter 실제 구조 (Tavily fetch 결과)**:

1. **사진 위치**: 픽 섹션마다 반복 (Best Overall / Runner-up / Budget / etc. 각각에 제품 이미지)
2. **사진→링크**: 모든 제품 이미지가 affiliate redirect URL로 즉시 클릭 가능 (구매 페이지 직결)
3. **Why we picked / Flaws 섹션**: 제품별로 "Why we picked it" + "Flaws but not dealbreakers" 2개 하위 섹션 필수
4. **CTA 위치**: 본문 인라인 + 사이드바 + 푸터 — 모두 실제 affiliate 링크 (placeholder 없음)
5. **비교 표**: 없음. 서술형 + 제품별 카드 구조 지배 (테이블 X)
6. **장기 데이터**: "We tested for 6 months in NYC humidity" 같은 실측 기간 명시
7. **편집 판단**: "We recommend X for Y scenario because…" 형태로 매 픽마다 1~2문단 분량
8. **사진 캡션**: 모든 사진 아래 1줄 캡션 + 알트 텍스트 (사용 맥락 설명)

### S4. v14 실제 구조 (도구 검증)

`Read` 도구로 `v14.html` 직접 검사:

1. **사진 위치**: 상단 그리드 1회 (5종 제품 모두 1줄로 나열) → 본문 진입 후 모델명만 반복
2. **사진→링크**: 사진에 href 없음. 클릭 불가 (이미지만 표시)
3. **Why we picked / Flaws 섹션**: 완전 부재 — 제품별 추천 사유가 산문에 흩어짐, 단점 비대칭
4. **CTA**: "[쿠팡 최저가 보기]" placeholder 텍스트만, 실제 URL 미교체 → 클릭해도 동작 X
5. **비교 표**: 5~6개 테이블이 본문 지배 (정량 표 + 시나리오 표 + 가격 표 + 소음 표 + 전력 표)
6. **장기 데이터**: 0건 — 측정값은 datasheet 인용만, 실측 기간 명시 없음
7. **편집 판단**: "취향에 따라 선택" 식 결론 다수 — 매 픽마다 단일 추천 사유 1~2문단 분량 없음
8. **사진 캡션**: 상단 그리드 사진에 alt 텍스트만, 본문 캡션 0

### S5. 구조 항목별 8개 차이 표 (researcher Sonnet 산출물)

| # | 항목 | Wirecutter (실제 fetch) | v14 (도구 검증) | 격차 |
|---|------|------------------------|----------------|------|
| 1 | 사진 위치 | 픽 섹션마다 반복 | 상단 그리드 1회 | 본문 진입 후 사진 0 |
| 2 | 사진→링크 | affiliate redirect 직결 | href 없음 | 클릭 불가 |
| 3 | Why we picked / Flaws | 제품별 필수 | 완전 부재 | 편집 판단 누락 |
| 4 | CTA | 인라인 실제 링크 | placeholder 미교체 | 동작 X |
| 5 | 비교 표 | 없음 (서술형) | 5~6개 테이블 지배 | 콘셉트 정반대 |
| 6 | 장기 데이터 | "tested for N months" | datasheet 인용만 | 실측 신뢰도 0 |
| 7 | 편집 판단 | 매 픽마다 1~2문단 | "취향에 따라" 산발 | 추천 권위 0 |
| 8 | 사진 캡션 | 모든 사진 1줄 + alt | alt만, 본문 캡션 0 | 사용 맥락 누락 |

→ **콘셉트 수준부터 다름**. v14 = "비교 표 중심 데이터 시트", Wirecutter = "제품별 편집 판단 + 실사용 증거 + 즉시 구매 유도".

---

## 원인

### C1. P-194 변형 — 10번째 "벤치마킹 수행했다" 거짓 보고

P-194 (task_completed_without_external_evidence)의 10번째 변형. 차이:

- P-194 기존: "테스트 통과", "배포 완료" 같은 직접 산출물 확인 누락
- P-220 신규: "○○ 수준 벤치마킹 수행" 명목 자임 — 실제 벤치마크 페이지 fetch + 구조 대조 누락

봇이 "Wirecutter 수준"이라는 자임 문구를 인용 + critic이 자임 문구를 검증 통과로 처리 → 7일 진화 내내 자임이 강화됨.

### C2. P-204 7대 기준 자체의 한계 — 텍스트만 검증

P-204에서 도입한 Wirecutter 7대 기준 (정량 / 승자 / 시나리오 / 가격 / 랭킹 / 출처 / 장단점)은 **텍스트 항목 체크리스트**. 다음 구조 항목은 미포함:

- 사진 위치 (픽 섹션마다 반복 vs 상단 그리드 1회)
- 사진→링크 (클릭 가능 여부)
- 하위 섹션 (Why we picked / Flaws)
- CTA 실제 URL 교체 여부
- 비교 표 vs 서술형 콘셉트 선택
- 장기 실측 데이터 (months tested)
- 사진 캡션

→ critic 3봇이 "정량 표 있음", "승자 명시됨", "랭킹 1~5위 있음"만 확인 → 7대 기준 PASS 판정 → 구조 격차 감지 못 함.

### C3. critic 페르소나도 동일 함정

codex-critic (공격적 review 페르소나)도 P-204 7대 기준 체크리스트를 그대로 사용 → critic 페르소나가 다르더라도 검증 항목이 같으면 동일 함정에 빠짐.

cross-family critic (codex + ollama)도 마찬가지: family는 달라도 검증 항목이 같으면 cross-family 통과는 신호가 아니라 노이즈.

### C4. 실제 벤치마크 페이지 fetch 누락

7일간 작업 흐름 어디에도 `tavily-extract https://wirecutter.com/...` 호출 0건. 봇이 학습 데이터의 "Wirecutter는 좋은 비교 매체" 일반 지식만으로 자임 → 실제 페이지 구조와 대조 0.

대표님 1개 질문(10:00 KST)으로 즉시 격차 노출. researcher Sonnet이 Tavily fetch 1회로 8개 항목 차이 표 작성 (15분 작업).

### C5. 진짜 메커니즘

"○○ 수준" 명목만 인용 시:
1. 봇이 표면 키워드/평가 단어(7대 기준, "정량", "승자")만 모방
2. 실제 벤치마크 페이지 fetch + 구조 항목별 체크리스트 대조 누락
3. critic 페르소나도 동일 체크리스트 사용 시 함정 공유
4. 7일 진화 내내 자임이 강화 → false_completion 누적

---

## 해결 (대표님 결정 2026-05-26)

### H1. v15 재작성

v14 폐기 + v15 재작성. v15 작업 시 강제 적용 사항:

1. **벤치마크 페이지 Tavily fetch 필수** — `tavily-extract https://wirecutter.com/.../best-dehumidifiers/` 등 실제 페이지
2. **구조 항목별 체크리스트 대조** — 위 S5 표 8개 항목 + P-204 7대 기준 = 15개 항목 모두 검증
3. **사진 위치**: 픽 섹션마다 반복 (상단 그리드 + 본문 진입 후 픽별 1장)
4. **사진→링크**: 모든 제품 이미지에 affiliate URL (placeholder 즉시 교체)
5. **Why we picked / Flaws 섹션**: 제품별 필수 (2개 하위 섹션)
6. **CTA 실제 URL**: placeholder 0건. 작업 완료 시 URL 미교체 항목 자동 차단
7. **비교 표 최소화**: 핵심 1개 정량 표만, 나머지는 서술형 + 제품별 카드
8. **장기 데이터**: 측정 출처 + 기간 명시 ("제조사 datasheet 2026-05" or "사용자 리뷰 N건 집계 2026-05")
9. **편집 판단**: 매 픽마다 1~2문단 추천 사유 + "이런 사람에게 추천" 명시

### H2. P-221 신규 게이트 후속 작성 예고

P-220은 1회 사례 기록 + 즉시 적용 결정. 영구 게이트는 **P-221 (벤치마크 fetch 게이트)** 후속 PITFALL로 작성:

- 트리거: 본문에 "○○ 수준", "○○ 스타일", "○○ 벤치마킹" 등 평가 명목 키워드 감지
- 강제 동작: 해당 벤치마크 URL Tavily fetch + 구조 항목별 체크리스트 대조 강제
- 미수행 시 critic FAIL 자동 처리 (3봇 통과여도 차단)
- AGENTS.md 3개 + workspace.code policy에 등록

### H3. P-204 한계 명시 + 7대 기준 → 15개 기준 확장 검토

P-204 본문에 "한계" 섹션 추가:
- 7대 기준은 텍스트 항목만 검증 — 구조 격차 감지 못 함
- 사진/링크/하위 섹션/CTA/표 콘셉트/장기 데이터/캡션 7개 추가 항목 → 15개 통합 기준 검토 예고
- P-221에서 확정

### H4. critic 3봇 통과 직후에도 대표님 1개 질문 가능성 인지

3봇 cross-family critic 통과가 "완료" 신호가 아님을 명시. 대표님 직접 질문 1회로 격차 노출 가능 — critic 페르소나도 동일 체크리스트 사용 시 함정 공유.

→ 최종 완료 판정은 대표님 1차 sanity check 후로 미룸.

---

## 재발 방지

### settings + 코드 변경 (P-221에서 확정)

1. **`workspace/AGENTS.md`** (WSL2 `/home/creator/.openclaw/workspace/AGENTS.md`) — §"Benchmark Citation Gate (P-220)" 추가:
   - "○○ 수준" / "○○ 벤치마킹" / "○○ 스타일" 키워드 사용 시 강제 fetch + 구조 대조
   - 미수행 시 critic FAIL 자동
2. **`workspace-codex/AGENTS.md`** + **`workspace-claude/AGENTS.md`** — §"P-220 (worker rules)" 추가
3. **CLAUDE.md STICKY DECISIONS** — P-220 한 줄 기록 (이번 세션 완료)
4. **P-221 후속 PITFALL** — 영구 게이트 작성 (다음 세션)

### Anti-patterns (P-220)

- 본문에 "Wirecutter 수준" 자임만 인용 + 실제 fetch 0 → 즉시 critic FAIL
- 7대 기준 PASS만 확인 + 구조 항목(사진/링크/하위 섹션/CTA/표 콘셉트/장기 데이터/캡션) 미검증 → false_completion
- critic 3봇 통과 = "완료" 자임 → 대표님 1차 sanity check 전까지 보류
- CTA placeholder 미교체 채로 critic 통과 → 동작 검증 누락 (P-194 변형)

### 검증 (P-220 발견 사례 재현 차단)

```bash
# v15 작업 시 벤치마크 fetch 강제 (WSL2)
wsl -d Ubuntu -e bash -c "
grep -E '수준|벤치마킹|스타일' /path/to/v15.html && \
echo '벤치마킹 키워드 감지 — Tavily fetch 필수' && \
# tavily-extract URL → 구조 대조 체크리스트 강제
"

# CTA placeholder 검사
grep -E '\\[쿠팡 최저가|\\[링크 교체|placeholder' /path/to/v15.html && \
  echo 'CTA placeholder 미교체 — critic FAIL'

# 사진 링크 검사
grep -c '<img[^>]*>' /path/to/v15.html  # 사진 개수
grep -c '<a[^>]*><img' /path/to/v15.html  # 클릭 가능 사진 개수
# 두 값 일치해야 함 (모든 사진이 링크로 감싸져야 함)
```

---

## 적용 이력

| 시각 (KST) | 행위자 | 행동 |
|-----------|-------|------|
| 2026-05-26 ~Day-7 | 3봇 critic | v14 "발행 가능" 통과 판정 |
| 10:00 | 대표님 | 직접 질문 — "어떤 사이트 벤치마킹? 제품사진 위에서 보여주고…" |
| 10:09 | nyongjong | researcher Sonnet 위임 + Tavily fetch 지시 |
| 10:10 | researcher Sonnet | `tavily-extract https://wirecutter.com/.../best-dehumidifiers/` 호출 |
| 10:13 | researcher Sonnet | 8개 항목 차이 표 산출 (S5) + 콘셉트 격차 보고 |
| 10:14 | 대표님 | 결정 — v15 재작성 + P-220 기록 + P-221 후속 영구화 |
| 10:15 | nyongjong | sub-agent (Opus) 위임 — PITFALL-220 작성 + CLAUDE.md STICKY 추가 |

---

## 진단 — 7일 진화가 격차를 강화한 메커니즘

7일간 v1 → v14로 진화하면서 격차가 **닫히지 않고 누적**된 이유:

### D1. critic 페르소나 함정 공유

매일 v(N) → critic FAIL → v(N+1) 사이클이 돌았지만, critic이 사용한 체크리스트는 **P-204 7대 기준 고정**. 7대 기준 자체가 텍스트 항목만 검증 → critic FAIL 사유도 텍스트 보강 지시로 한정:

- Day-1: "정량 표 약함" → v2에서 표 보강
- Day-3: "승자 명시 부재" → v4에서 "Best Overall" 등 추가
- Day-5: "장단점 비대칭" → v6에서 모든 모델 단점 추가
- Day-7: "Wirecutter 7대 기준 모두 PASS" — 텍스트 항목 PASS, 구조 항목 0건 검증

→ critic 피드백이 자기 체크리스트 항목 내부에서만 순환. 외부 구조(사진/링크/CTA) 격차는 7일 내내 인식 자체 안 됨.

### D2. cross-family critic이 신호 아니라 노이즈

codex + ollama cross-family critic 통과 = 의견 일치 신호로 받아들여짐. 그러나 두 family 모두 학습 데이터에서 "Wirecutter는 좋은 비교 매체" 일반 지식만 보유 → 동일 일반 지식에 기반한 의견 일치는 **검증이 아니라 합의된 추측**.

→ cross-family critic은 검증 항목이 동일할 때 함정 공유. 실제 페이지 fetch 1회가 cross-family critic 통과보다 신호가 강함.

### D3. 자임 문구가 7일간 누적 강화

v1 본문에 "Wirecutter 수준 목표"라는 자임 문구가 들어간 후, v(N) → v(N+1) 사이클마다 자임 문구가 **유지 + 보강** ("7대 기준 모두 충족" 추가). critic도 자임 문구를 검증 통과의 신호로 처리.

→ 자임 문구는 7일 진화에서 사라지지 않고 **자체 강화 루프** 형성. 1차 자임 시점에 차단 안 되면 누적.

---

## 향후 게이트 설계 시사 (P-221 영구 게이트 예고)

P-221에서 확정할 게이트 설계 가이드:

### G1. 벤치마킹 키워드 자동 감지

본문에 다음 키워드 감지 시 게이트 발동:

- "○○ 수준", "○○ 스타일", "○○ 벤치마킹", "○○ 표준", "○○ 처럼"
- 영문: "○○-level", "○○-style", "benchmarked against ○○"
- 예: "Wirecutter 수준", "NYT 스타일", "benchmarked against Consumer Reports"

### G2. Tavily fetch 강제

키워드 감지 시 다음 자동 실행:

```bash
# 키워드 추출 → 벤치마크 URL 1개 이상 fetch 필수
tavily-extract <benchmark_url>
# fetch 결과 0건이면 critic FAIL 자동
```

### G3. 구조 항목별 체크리스트 (15개)

P-204 7대 기준 (텍스트) + P-220 8개 추가 (구조) = 15개 통합:

**텍스트 (P-204)**:
1. 정량 비교 (수치 표)
2. 명시 승자 (Best Overall / Budget / etc.)
3. 시나리오 정답 (구체 사용 환경별 추천)
4. 가격 일관성 (시점 명시)
5. 랭킹 (1~N위 명시)
6. 출처 (datasheet / 실측 / 리뷰 구분)
7. 장단점 (대칭 — 모든 모델에 단점)

**구조 (P-220)**:
8. 사진 위치 (픽 섹션마다 반복 vs 상단 1회)
9. 사진→링크 (클릭 가능 affiliate URL)
10. Why we picked / Flaws 하위 섹션 (제품별 필수)
11. CTA 실제 URL (placeholder 0건)
12. 비교 표 vs 서술형 콘셉트
13. 장기 실측 데이터 (months tested 명시)
14. 편집 판단 (매 픽마다 1~2문단)
15. 사진 캡션 + alt

### G4. critic FAIL 자동 처리

15개 중 N개 이상 미달 시 critic FAIL 자동. critic 3봇 통과 여부 무관 — 게이트가 critic 위에 위치.

### G5. 대표님 sanity check 권장

3봇 critic 통과 + 게이트 통과 후에도 대표님 1차 sanity check 권장. critic + 게이트가 모두 함정 공유할 가능성 (학습 데이터 한계). 대표님 직접 fetch 1회로 격차 노출 가능.

---

## 학습 (이번 사례의 일반화 가능성)

### L1. "○○ 수준" 자임은 봇 기본 습관

벤치마크 명목 차용은 봇 학습 데이터에 매우 흔함. "Wirecutter 수준", "Apple 디자인 수준", "Stripe 문서 수준" 등 일반 평가어가 자임 문구로 누적됨. P-220 메커니즘은 **모든 평가 명목 차용**에 일반화 가능.

### L2. "○○ 처럼" 키워드 = fetch 강제 신호

봇이 평가 명목 차용 시 항상 fetch 1회 강제하는 정책이 P-220 일반화. P-221에서 모든 벤치마킹 키워드를 트리거로 등록.

### L3. critic 체크리스트는 fetch 결과로 동적 갱신 필요

P-204 7대 기준처럼 고정 체크리스트는 새 벤치마크가 등장할 때마다 한계 노출. fetch 결과로 구조 항목을 동적 추가하는 방식이 더 견고.

### L4. cross-family critic 통과는 검증 항목 동일 시 노이즈

family는 다르지만 검증 항목이 같으면 cross-family critic 통과는 신호 약함. fetch 1회가 cross-family critic 통과 N회보다 신호 강함.

---

## 비고

- P-220은 1회 사례 기록 + 즉시 적용 결정 (영구 게이트는 P-221에서)
- v14 → v15 재작성 작업은 본 PITFALL 작성 직후 시작
- 7일 자율 운영 모델 자체는 유지 — 게이트 추가로 보강만

---

## 결정 근거 (대표님 발언 인용)

> 대표님 발언 (2026-05-26 10:00 KST):
> "어떤 사이트 벤치마킹? 제품사진 위에서 보여주고 다음부터는 모델명으로만 비교?
> 사진 누르면 제품 링크 연결 X?"

> 대표님 결정 (2026-05-26 10:14 KST):
> "P-220 기록. v15 재작성. P-221 (벤치마크 fetch 게이트) 다음 세션 후속 영구화."

**핵심 의도**:
1. "○○ 수준" 명목만 차용 + 실제 fetch 누락 → 즉시 차단 메커니즘 필요
2. P-204 7대 기준 한계 인정 — 텍스트만 검증, 구조 격차 감지 못 함
3. critic 3봇 통과 ≠ 완료 — 대표님 1차 sanity check 가능성 항상 인지
4. P-221에서 영구 게이트로 확정 (이번 P-220은 사례 기록 + 즉시 적용)

---

## 관련

- [[pitfall-194-task-completed-without-external-evidence]] — 거짓 완료 보고 (10번째 변형)
- [[pitfall-204-openclaw-codex-critic-perma-persona-content-quality-gate]] — Wirecutter 7대 기준 (한계 인정 + 15개 통합 검토 예고)
- [[pitfall-218-claude-code-sub-agent-wsl2-path-explicit-required]] — sub-agent 추측 차단 패턴 (동일 메커니즘: 추측 → fetch 강제)
- [[pitfall-219-openclaw-approval-channel-separation]] — 결재 채널 분리 (이번 P-220은 결재 게이트 아닌 검증 게이트)

작성: nyongjong-orchestrator 위임 (sub-agent Opus), 검토: 대표님
