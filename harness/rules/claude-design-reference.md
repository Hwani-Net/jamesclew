# Claude Design Reference — Anthropic Labs (2026-04-17 launch)

출처: claude.ai/design 공식 + engincanveske.substack.com 비교 리뷰 + Anthropic Labs Reddit announcement
등록일: 2026-05-16

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
