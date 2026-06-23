---
description: "일일 트렌드 디제스트(AI/IT 뉴스 + GitHub 급상승) 자동 트리아지 — JamesClaw 관련성 채점, 격차충족 후보만 watchlist+결재 에스컬레이션, 나머지 드롭(노이즈 차단)"
argument-hint: "[디제스트 텍스트 또는 파일경로] (생략 시 직전 대화/클립보드에서 추출)"
allowed-tools: Bash, Read, Write, Grep, AskUserQuestion
---

# /trend-triage — 트렌드 디제스트 자동 트리아지

매일 도는 "AI/IT 뉴스 + GitHub 급상승" 스케줄 디제스트를 받아 **JamesClaw 관련성**으로 채점하고, **격차충족 후보만** 추려 watchlist + 결재로 올린다. 나머지는 버려 노이즈를 막는다. "추려서 올리기"까지가 범위 — 실제 채택은 대표님 결재 후.

## 설계 원칙
- **비용 우선(멀티모델)**: 벌크 채점은 저비용(codex/Sonnet/Haiku), 격차후보 1~2건만 메인 모델 심층. (shadcn/improve = 고성능 감사 → 저비용 실행 패턴.)
- **결정론 먼저(Reins P-256)**: repo 메타(이름/언어/stars/URL)는 regex로 추출 → LLM은 관련성 판단만.
- **"이미 보유?" 먼저(P-109)**: 우리가 이미 가진 능력이면 ✅보유로 드롭. 중복 구축 금지.
- **명목 아닌 구조 대조(P-220)**: "에이전트 OS" 키워드만으로 후보 판정 금지 → `rules/agent-os-landscape.md` 매핑표·격차와 대조.
- **중복 에스컬레이션 금지**: watchlist에 이미 있는 URL은 재상신 안 함(디제스트는 매일 반복).

## 절차

### 1. 결정론 추출
인자(텍스트/파일경로) 없으면 직전 대화 디제스트 사용. repo 항목 형식 `- owner/repo 설명: … 언어: … stars: N … URL: https://…` 을 bash/regex로 `{name,lang,stars,todayStars,url,desc}` 배열화 + 트렌드 요약 bullet 분리.

### 2. 사전 필터 (규칙, 무료)
도메인 무관 즉시 드롭: 주식·트레이딩, 순수 인프라(DB·냉각·전력·GPU). 단 도메인 키워드(`agent·coding·skill·memory·browser·sandbox·harness·codex·claude·LLM·video·voice·security·MCP·orchestrat·workflow`) 포함 시 통과.

### 3. 관련성 채점 (저비용 모델, 배치 1회)
생존 항목을 agent-os-landscape 매핑표 + **알려진 격차**(①체크포인트-재개 ②브라우저 /browse ③영상 ④보안)와 대조:
- **category**: agent-os / coding-workflow / skills / memory / browser / video-voice / security / infra / other
- **relevance**:
  - **3 🎯 격차충족후보** — 알려진 격차를 메우거나, 우리가 쓰는 것의 *명백히 나은* 버전. **자동조건: `agent-os-landscape`의 ⚠️ 격차 행에 매핑되면 채택경로(직접설치 가능여부) 무관 rel-3** — 에스컬레이션은 '직접 설치'가 아니라 '격차 설계 결정'을 위한 것(예: eve=TS프레임 직접채택X여도 #1 격차 레퍼런스라 rel-3).
  - **2 🔍 관찰** — 인접·참고 가치, 지금 채택 아님
  - **1 ✅ 보유** — 이미 보유(검증용, 드롭)
  - **0 ❌ 무관** — 도메인 밖
- 각 항목 **1줄 근거 + 액션**. 확신 없으면 보수적으로 2(관찰).

### 4. 에스컬레이션 (relevance=3 만)
watchlist 중복 체크 → 신규만 (**URL 정규화 후 비교**: 끝 `/`·`.git`·쿼리 제거, `http→https`). **단 rel-2로 기록된 항목이 격차행 매핑/신기능 출시로 rel 상승 시 재상신 허용**(사유 기록 — dedup이 정당한 업그레이드를 막지 않게):
- `harness/docs/trend-watchlist.md` append (deploy.sh가 옵시디언 자동 미러): `| 날짜 | repo | cat | 근거/격차 | 액션 | rel | URL |`
- 결재후보 push: `echo "[Trend triage] <repo> — <격차> 충족 후보. 채택 검토?" >> ~/.harness-state/last_result.txt` (Stop hook 텔레그램) 또는 Discord #결재-필요(1508626494711140444). **하루 push 최대 3건 — 초과 시 1개 묶음 메시지로 batch**(알림 폭주 방지).
- relevance 2(관찰)는 watchlist에 `관찰`로만 기록(push 없음).

### 5. 드롭 + 1화면 요약
relevance 0~1은 버린다(개별 보고 금지). 출력:
```
## Trend Triage <날짜>
총 N repo | 🎯격차후보 X | 🔍관찰 Y | (✅보유/❌무관 Z 드롭)

### 🎯 격차충족 후보 (에스컬레이션됨)
1. owner/repo [cat] — <격차> 충족. 액션: <1줄>. (URL)

### 🔍 관찰 (watchlist 기록)
- owner/repo — <1줄>
```
트렌드 bullet은 **우리 도메인 영향 있는 것만** 1~2줄.

## 자동화 (스케줄 연동)
- 일일 디제스트 직후 자동 실행: 디제스트 생성 스케줄 작업 끝에 `/trend-triage <디제스트>` 트리거 추가, 또는 `/loop 24h /trend-triage`(architecture.md /loop 패턴).
- **결재후보 0건이면 push 없음(조용함)**. 1건+면 #결재-필요로 1건씩. → 매일 봐도 피로 없음.

## 주의
- dedup(정규화 URL 기준) 필수 — 같은 repo 재상신 금지. **단 rel 상승(격차 충족) 시 재상신 허용.**
- **watchlist bloat 방지**: 관찰(rel-2) 30일 무변동 시 드롭 로그로 이동(월 1회 prune).
- 격차후보 판정은 agent-os-landscape 대조 필수(명목 금지).
- triage는 분류·상신까지. 채택·구축은 별도 작업 + 결재.

## 관련
- [[agent-os-landscape]] — 관련성/격차 판정 기준(매핑표)
- [[quality]] Reins(P-256) · P-109(보유 우선) · P-220(구조 대조)
