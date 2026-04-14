---
description: "Vision 기반 디자인 리뷰. Stitch 디자인 생성 후 실행. 스크린샷을 Opus Vision으로 직접 분석하여 색상, 레이아웃, UX, 타이포그래피 개선안을 도출. Stitch edit_screens로 자동 반영."
---

# /design-review — Vision 디자인 리뷰어

## 언제 사용하나?

```
/stitch-design (생성) → /design-review (이것) → 대표님 승인 → /react:components → /design-audit (MCP)
```

- Stitch에서 디자인 생성 후, 코드 변환 전에 실행
- 디자인 품질을 한 단계 높이고 싶을 때

## 실행 절차

### Step 1: Stitch 스크린샷 캡처

Stitch MCP 또는 expect MCP로 스크린샷 확보:

```
방법 A (Stitch MCP):
  mcp__stitch__fetch_screen_image → PNG 다운로드

방법 B (expect MCP):
  mcp__expect__open → Stitch 프로젝트 URL
  mcp__expect__screenshot → 각 스크린 캡처
  mcp__expect__close

방법 C (Chrome):
  mcp__claude-in-chrome__navigate → Stitch URL
  mcp__claude-in-chrome__computer(action: screenshot)
```

### Step 2: Opus Vision 직접 리뷰

스크린샷을 Read 도구로 읽어 Opus가 직접 시각 분석:

```
Read(file_path: "/tmp/stitch-screenshot.png")

분석 관점 (design_rubric.md 4대 축 기준):
1. Design 일관성 — spacing/color/radius 토큰 체계
2. 독창성 — AI 클리셰 블랙리스트 확인
3. 완성도 — Typography 계층, 대비율, 간격 리듬
4. 기능성 — CTA 명확성, 인터랙션 시각 피드백
```

**외부 모델 교차 검수** (design_rubric.md 기반):
```bash
# Codex에 rubric 평가 위임 (5H 0 소비)
bash harness/scripts/codex-rotate.sh "다음 디자인을 design_rubric.md 4대 축으로 평가하라.
각 축 0-10점 + 근거. JSON 출력.

디자인 설명:
$(cat /tmp/design-description.txt)"
```

### Step 3: 개선안 정리

```
🎨 Vision Design Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 스크린: {스크린 이름}
📊 Rubric 점수: 일관성 {N}/10 | 독창성 {N}/10 | 완성도 {N}/10 | 기능성 {N}/10

개선 제안:
1. [색상] {구체적 hex 값 변경}
2. [타이포] {font-size/weight 변경}
3. [레이아웃] {padding/gap 변경}
4. [효과] {shadow/blur/transition 추가}
5. [독창성] {AI 클리셰 탈피 방안}

적용 여부: 대표님 승인 후 Stitch edit_screens로 반영
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Stitch에 반영 (대표님 승인 후)

대표님이 승인한 항목만 Stitch MCP `edit_screens`로 적용:
```
mcp__stitch__edit_screens → 승인된 수정 사항 반영
```

## 비용

- **Opus Vision**: 5H 풀 소비 (외부 API 비용 0)
- **Codex 교차 검수**: 5H/7D 0 소비
- 외부 API(GPT-4o) 불필요

## Fallback

- Stitch MCP 미연결 → expect MCP 또는 Chrome으로 스크린샷
- 스크린샷 캡처 실패 → Stitch `fetch_screen_code`로 텍스트 기반 리뷰
- **절대 design-review를 스킵하고 react-components로 넘어가지 않는다**
