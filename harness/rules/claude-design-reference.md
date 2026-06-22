# Claude Design Reference — Anthropic Labs (2026-04-17 launch)

출처: claude.ai/design 공식 + engincanveske.substack.com 비교 리뷰 + Anthropic Labs Reddit announcement + 홍아린 AI 영상 `vHmJg8VQW5c`(실전 4단계 워크플로, 2026)
등록일: 2026-05-16 (2026-06-21 실전 워크플로 섹션 추가)

## 사용 규칙

- **마감 단계 전용**: 탐색은 Stitch (무료), 폴리시·핸드오프는 Claude Design.
- 매 세션은 Claude 구독 credits 소비 — 5화면 앱 한 세션이 Pro 사용량에 체감 큼.
- **GitHub repo 기반 design system 자동 추론**이 핵심 차별점. Lovable/v0/Figma 모두 못 함.

---

## Claude Design 핵심 정의

Anthropic Labs의 AI design tool. 출시 시점(2026-04) 디폴트는 **Claude Opus 4.7 vision** — 외부 도구라 현재 디폴트는 사용 시 재확인 (우리 메인 세션은 2026-06-11부터 Opus 4.8).

### 산출물 유형
- Mockup, Prototype
- Slides (PPTX export)
- One-pagers
- Landing pages
- Branded visuals (brand asset)
- **Claude Code handoff bundle** (← 핵심 통합 포인트)

### Export 형식
- PDF
- PPTX
- HTML
- URL (shareable)
- **Handoff bundle (Claude Code 직통)** — design tokens + components + screens가 한 묶음

---

## UI 구조

- **Split layout**: 좌측 chat panel + 우측 canvas.
- 디자인 → 인라인 코멘트 → 부분 수정 → 반복.
- 화면 단위 부분 수정이 정밀 (전체 재생성 회피).

---

## 핵심 차별점 (Stitch와 비교)

### 1. GitHub Repo 자동 인식 → Design System 추론
**Lovable/v0는 Figma import만 가능. Claude Design은 GitHub 코드베이스에서 직접 토큰을 추출.**

- 기존 프로젝트 (Firebase 블로그, CMS 등)에 새 화면 추가 시:
  - Claude Design에 GitHub URL 또는 zip 전달
  - 코드의 Tailwind config, CSS variables, 컴포넌트 패턴 자동 분석
  - 동일한 design system을 따르는 새 화면 생성
- 우리 시나리오: `MultiBlog/` 또는 `Jamesclew/` 새 페이지 추가 시 이 기능 활용.

### 2. Claude Code 직통 핸드오프
- 디자인 완성 후 **Handoff Bundle** 생성 → Claude Code가 그 bundle을 import.
- Claude Code는 우리 Firebase 프로젝트 구조에 맞춰 React/HTML/CSS 자동 작성.
- 우리 워크플로: `Claude Design → handoff → Claude Code → Firebase deploy` 단일 ecosystem.

### 3. Vision 정확도 (Opus 4.7)
- 스크린샷 입력 → 기존 디자인 분석 → 동일 스타일로 새 화면 생성.
- 경쟁사 사이트 캡처 → 우리 스타일로 변환 가능.
- 단, 우리 정책: **Sonnet Vision 금지, 메인 세션 최상위 모델 직접**(현 Opus 4.8) — Claude Design 자체 모델(출시 시 Opus 4.7)도 상위 티어라 정책 부합.

### 4. 인라인 코멘트 + 부분 수정
- 캔버스의 특정 영역에 코멘트 → 그 부분만 재생성.
- 다른 화면 영향 최소화. Stitch도 가능하지만 Claude Design이 더 정밀.

---

## Stitch와의 명확한 경계

| 작업 | Stitch | Claude Design |
|------|--------|---------------|
| 무료 탐색·실험 | ✅ | ❌ (credits 소비) |
| 멀티 화면 한 호출 (5+) | ✅ | 가능하지만 비용 |
| Voice 인터페이스 | ✅ | ❌ |
| 인터랙티브 prototype (Play 모드) | ✅ | ❌ |
| GitHub repo 기반 design system | ❌ | ✅ |
| Claude Code 직통 핸드오프 | DESIGN.md export 필요 | ✅ 네이티브 |
| Vision 분석 정확도 | 중간 | ✅ Opus 4.7 |
| 브랜드 asset (slides, one-pager) | 약함 | ✅ 강점 |
| 부분 수정 정밀도 | 중간 | ✅ |

---

## 권장 워크플로 (Stitch + Claude Design + Claude Code)

```
[탐색 단계]
  Stitch (무료) → Voice Canvas로 idea 발산
                → 5화면 단일 생성 → Play 모드로 UX 검증
                → DESIGN.md export

[마감 단계]
  Claude Design → GitHub repo 또는 DESIGN.md import
               → 정밀 폴리시 (Opus 4.7 Vision)
               → 인라인 코멘트로 부분 수정
               → Handoff Bundle 생성

[구현 단계]
  Claude Code   → Handoff Bundle import
               → 우리 Firebase 프로젝트에 통합
               → /design-review (Opus Vision) 으로 라이브 vs 디자인 비교
               → drift-guard로 토큰 일관성 검증
               → /blog-publish 또는 firebase deploy
```

---

## 실전 제작 워크플로 (영상 기법 — 홍아린 AI `vHmJg8VQW5c`, 2026)

> Claude Design + Claude Code 페어로 "AI 티 안 나는 고퀄 사이트"를 만드는 4단계. **핵심 명제: 디자인은 Claude Design, 작동·애니메이션은 Claude Code — 한쪽 단점을 다른 쪽이 메운다.** (영상은 Stitch 없이 두 툴만으로 30분 완성 시연.)

### 1단계 — 참고 디자인 ≥3장 먼저 수집 (결과물을 가르는 핵심)
- 프롬프트만 넣으면 Claude Design·v0·Bolt 모두 **AI 티 나는 똑같은 디자인** → 차별화 0. 대부분 이 단계를 건너뛰고 여기서 결과가 갈린다.
- Pinterest(+ designspace, worldofportfolios)에서 만들 디자인 키워드 검색 → 마음에 드는 화면 **최소 3장** 캡처해 첨부.
- **1장=따라그림(복제), 3장+=방향 학습(차별화)** — 우리 P-081(reference=차별화이지 복제 아님)·P-220(벤치마크 구조 대조) 정합.

### 2단계 — Claude Design로 디자인 뽑기
- Prototype 탭. **와이어프레임 말고 Hi-Fidelity** 선택 — 토큰 더 쓰지만 왕복 수정 횟수가 급감(순비용 절감).
- **Design System 토글 기본 OFF** — 켜면 매 요청마다 전체를 읽어 시작부터 토큰 과소비 + **Claude Design ↔ Claude Code는 사용량(quota) 별도**라 초반 낭비 시 그 주 내내 고생. (꼭 쓰려면 영상에서 소개한 "겟디자인위키"류 사이트 — 실제 브랜드(Apple 등) 디자인 시스템 정리본 — 에서 색·폰트·버튼 복사 → Create에 붙여넣기. ⚠️ 정확한 URL은 영상 자막상 불명확 → 고정댓글 확인 후 사용.)
- 프롬프트 공식 = **브랜드 + 필요한 섹션 + 원하는 분위기**. Claude가 색감·타겟·무드를 역질문 → 답하거나 "알아서 해줘". 참고 3장 첨부 필수.

### 3단계 — 수정 3종 (용도·토큰 차이 큼)
| 방법 | 용도 | 토큰 |
|------|------|------|
| **Edit** | 요소 직접 클릭 → 크기·색·폰트·투명도 즉시 변경 | 적음 |
| **Comment** | 요소 핀 + "이거 지워" → **그 부분만**, 나머지 절대 불변 | 적음 |
| **Tweaks(트윅스)** | 슬라이더로 색·폰트·여백·회전·콘텐츠 실시간 조절 | **0 (프롬프트 불필요)** |

- **Tweaks가 킬러 기능**: 한 번 켜면 원하는 조합 정할 때까지 **무한정 토큰 0**으로 다듬기. "한 번에 뽑는 게 아니라 무한 빠르게 다듬는다." → 우리 5H/7D 비용 정책과 정합, 적극 활용.
- **스타일 탐색 ("목록 먼저")**: `이 디자인을 완전히 다른 스타일로 여러 개 제안. 먼저 가능한 스타일 목록부터 나열해줘.` ← **마지막 문장이 핵심**(Claude가 임의로 고르지 않고 목록 제시 → 사용자 선택). 우리 **P-213/P-217 "옵션 목록 먼저"** 와 동일 패턴. 고른 스타일로 재생성(메뉴·내용 유지, 디자인만 교체). `트윅스 개수 늘려줘`로 탐색 폭 확대.
- ⛔ **Claude Design에서 애니메이션 넣지 말 것** — 작업 몇 번에 한 주치 토큰 증발. 디자인만 뽑고 끝. 움직임·반응은 Claude Code가 훨씬 잘함.

### 4단계 — Claude Code 핸드오프 + 작동화 + 애니메이션
- Share → **"Handoff to Claude Code"** → 생성된 명령어 복사 → VS Code/Cursor 터미널의 Claude Code에 붙여넣기. 색·폰트·레이아웃·섹션 + **Tweaks까지 그대로 보존**(배포 시 Tweaks만 제거).
- **이미지 교체**: `input/` 폴더 생성 → 이미지 저장 → `input 폴더 이미지를 각 자리에 맞게 넣고 텍스트도 바꿔줘` (말 한마디로 끝).
- **애니메이션**: 전용 무료 애니메이션 컴포넌트 라이브러리 사이트(전 세계 디자이너 애니메이션 모음 — 움직이는 버튼·카드 플립·슬라이딩 후기·호버 가격표; ⚠️ 정확한 사이트명 자막 불명 → 영상 고정댓글 확인)에서 복사 → Claude Code에 주며 **"할 것 + 안 할 것 동시 지시"**: `이 섹션 디자인은 절대 건드리지 마, 카드 올라오는 애니메이션만 가져와.` ← 우리 **Karpathy G3(surgical changes)·regression-guard** 와 정합. 딴 데 손 안 댐.
- **시그니처 효과(스크롤 비디오 히어로)**: 라이브러리에서 `scroll video expansion hero` → `input/`에 이미지 1 + 루프 영상 1 → `히어로를 이걸로 교체, 영상이 루프 재생되며 나타나게.`

### 영상 기법 → 하네스 적용 메모
- 우리 블로그/랜딩(`smartreview`, `gpt-korea`) 신규 페이지 제작 표준 경로: ①Pinterest 3장+ 수집 → ②Claude Design Hi-Fi + **Tweaks 0토큰 폴리시** + "목록 먼저" 스타일 탐색 → ③Handoff → Claude Code(Firebase 통합) → ④애니메이션 "do+don't" 프롬프트.
- 검증은 기존대로: `/design-review`(메인 모델 Vision) 라이브 대조 + drift-guard 토큰 일관성 + `verify-deploy.sh`.
- **비용 우선순위**: Tweaks/Comment(0~소액) 우선, 재생성·Handoff·Claude Design 애니메이션은 토큰 큰 작업 → 결재 인지(P-168).

## 비용 가이드 (Pro 구독 기준)

- **5화면 mock + 폴리시 1세션**: Pro 일일 한도의 약 20~30% 체감 (저자 측정)
- **Handoff Bundle 생성**: 추가 비용 (큰 작업)
- **반복 인라인 코멘트 수정**: 코멘트당 적은 비용 (재생성과 다름)

### 절약 전략
1. **Stitch에서 5화면 모두 완성** → DESIGN.md export
2. Claude Design은 **DESIGN.md import 후 폴리시만** — 0부터 시작 X
3. 폴리시 → Handoff Bundle 1회 생성 → Claude Code 이관
4. 추가 수정은 Claude Code 내에서 진행 (Claude Design 재호출 회피)

---

## 우리 하네스 통합 포인트

### 1. `/design-review` 스킬과 연계
- Claude Design 출력 → 라이브 페이지 배포 → `/design-review` 호출 → Opus Vision으로 pixel-level 비교
- 차이 감지 시 인라인 코멘트로 Claude Design에 피드백 → 수정 → 재배포

### 2. drift-guard 통합 (P-054 라인)
- Claude Design의 Handoff Bundle에 design tokens (color, spacing, typography) 포함
- 우리 repo의 `.drift-guard.json`에 그 토큰 등록 → 배포 시 자동 검증
- 미일치 시 `verify-deploy.sh`가 `exit 2`로 배포 차단

### 3. 옵시디언 미러
- Claude Design 산출물의 핵심 디자인 결정은 `$OBSIDIAN_VAULT/06-raw/<date>-design-<slug>.md`에 저장
- BASB Raw tier → Distilled (내 관점 추가) → Synthesized (재사용 패턴) 진화

### 4. 비용 추적
- Claude Design 세션 후 `~/.harness-state/api_cost_log.jsonl`에 기록
- 형식: `{"date":"2026-05-16","service":"claude-design","cost_usd":<n>,"purpose":"<project>"}`

---

## 주의·제약 (저자 검증)

1. **세션 credits 압박**: 자유로운 실험에 부담 — Stitch 우선 사용.
2. **현재 모바일 디자인은 Stitch보다 약함** (저자 측정 시점 2026-04-17 직후. 업데이트 추적 필요).
3. **단독 도구 아님**: Anthropic은 Claude Design을 "ecosystem 일부"로 명시. Claude Code 없이 핸드오프 가치 절반 이상 손실.
4. **Lovable/v0/Figma 대체 X**: 보완재. 디자이너 직접 산출물 통제가 필요한 경우 Figma 병용.

---

## 검증 체크리스트 (Claude Design 산출물 → 우리 프로젝트 통합)

- [ ] DESIGN.md 또는 Handoff Bundle import 완료
- [ ] design tokens가 `.drift-guard.json`에 반영
- [ ] Claude Code가 우리 Firebase 프로젝트 구조에 맞게 통합 (`MultiBlog/` 또는 `Jamesclew/`)
- [ ] `/design-review` Opus Vision으로 라이브 비교 → PASS
- [ ] `verify-deploy.sh` 통과 (drift-guard 포함)
- [ ] 옵시디언 `06-raw/`에 디자인 결정 기록
- [ ] `api_cost_log.jsonl`에 비용 기록

---

## 향후 업데이트 추적

- Claude Design은 신규 (2026-04-17 launch). 6개월 내 큰 기능 추가 예상.
- 본 reference는 발견하는 대로 끝에 "Update N" 섹션 추가.
- Stitch 동향과 격차 추적: `rules/stitch-design-reference.md` 참조.

## 관련

- [[stitch-design-reference]] — Stitch 사용 패턴 + DESIGN.md export
- [[architecture]] — Vision 라우팅 정책 (Opus 우선)
- [[quality]] — Design Review Pass 5 (렌더링 검증)
