# Multi Blog — DESIGN.md

> 작성일: 2026-04-08 | 기반: Stitch MCP 디자인 시스템 (`assets/7708101689804681370`) + PRD v2.0
>
> **정체성**: 개인용 멀티 블로그 통합 발행 데스크톱 도구. 미니멀 + 데이터 중심 + 약간의 친근함. 1인 운영자 친화.

## 1. 디자인 토큰

### Color Palette (Dark mode 우선)

| Token | Hex | 용도 |
|-------|-----|------|
| `primary` (Indigo) | `#4F46E5` | CTA, 활성 상태, 진행 중 |
| `primary-hover` | `#4338CA` | 버튼 hover |
| `accent` (Lime) | `#84CC16` | 발행 성공, 진행률 완료 |
| `accent-soft` | `#84CC1622` | 성공 배경 alpha |
| `surface` (Slate Dark) | `#0F172A` | 페이지 배경 |
| `surface-elevated` | `#1E293B` | 카드 배경 |
| `surface-overlay` | `#334155` | 모달, 오버레이 |
| `border` | `#334155` | 구분선, 카드 외곽 |
| `text-primary` | `#F1F5F9` | 본문, 제목 |
| `text-secondary` | `#94A3B8` | 라벨, 캡션 |
| `text-tertiary` | `#64748B` | placeholder, disabled |
| `warning` (Amber) | `#F59E0B` | 봇 차단·rate limit 경고 |
| `error` (Rose) | `#F43F5E` | 발행 실패 |
| `info` (Sky) | `#38BDF8` | canonical URL 배지, 정보 |

### Typography (Inter)

| Token | Size | Weight | Line Height | 용도 |
|-------|------|--------|-------------|------|
| `display-lg` | 32px | 700 | 40px | 페이지 메인 제목 |
| `headline-lg` | 24px | 700 | 32px | 섹션 제목 |
| `headline-md` | 20px | 600 | 28px | 카드 제목 |
| `headline-sm` | 18px | 600 | 24px | 리스트 항목 |
| `body-lg` | 16px | 400 | 24px | 본문 |
| `body-md` | 14px | 400 | 20px | 작은 본문 |
| `label-md` | 12px | 500 | 16px | 라벨, 메타 |
| `label-sm` | 11px | 500 | 14px | 배지, 캡션 |
| `mono` | 13px | 400 | 18px | 코드, URL |

### Spacing (Tailwind 기준 4px grid)

`4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 / 96`

### Radius

| Token | px | 용도 |
|-------|----|------|
| `radius-sm` | 6px | 배지, 작은 버튼 |
| `radius-md` | 8px | input, dropdown |
| `radius-lg` | 12px | **카드, 메인 버튼 (Stitch ROUND_TWELVE)** |
| `radius-xl` | 16px | 모달 |
| `radius-full` | 9999px | 진행바 끝, 아바타 |

### Shadow (Dark mode)

```css
--shadow-sm: 0 1px 2px rgba(0,0,0,0.4);
--shadow-md: 0 4px 12px rgba(0,0,0,0.5);
--shadow-lg: 0 12px 24px rgba(0,0,0,0.6);
--shadow-glow: 0 0 0 3px rgba(79,70,229,0.4);  /* focus ring (Indigo) */
```

---

## 2. 컴포넌트 인벤토리 (V1)

### 2.1 사이드바 (240px width)
- 로고: "Multi Blog" + 버전 v2.0 라벨
- 메뉴 아이템 (수직 리스트, 8px gap):
  - 발행 (active = Indigo 좌측 보더 4px + Indigo bg alpha)
  - 큐
  - 통계
  - BYOC 체인
  - 설정
- 하단 footer:
  - 헬퍼 연결 인디케이터: 녹색 점 (#22C55E) + "헬퍼 연결됨"
  - 마지막 핑 시각 (label-sm)

### 2.2 통합 발행 진행 카드 (5플랫폼)
**구조**: 카드 1개 = 글 1건. 내부에 5플랫폼 진행바.

```
┌──────────────────────────────────────────────────┐
│  📝 AI 코딩 자동화 가이드 2026                     │ ← headline-md
│  발행 시작 12분 전  •  Tier 1 즉시 발행            │ ← label-md secondary
│ ─────────────────────────────────────────────── │
│  🟢 WordPress     ████████████████  100%  [URL]  │ ← Lime
│  🟢 Blogger       ████████████████  100%  [URL]  │ ← Lime
│  🔵 네이버 블로그  ███████████░░░░░   67%   ⏳    │ ← Indigo
│  🔵 티스토리      ███████░░░░░░░░░   45%   ⏳    │ ← Indigo
│  🟢 개인 블로그   ████████████████  100%  [URL]  │
│ ─────────────────────────────────────────────── │
│  canonical: https://aicreator.kr/2026/04/...      │ ← info badge
└──────────────────────────────────────────────────┘
```
- 카드: `surface-elevated` + `radius-lg` + `shadow-md`
- 진행바: 4px 두께, `radius-full`
- 진행 중 = Indigo, 완료 = Lime, 실패 = Rose
- canonical 배지: info color, mono font

### 2.3 시차 발행 타임라인
**구조**: 가로 타임라인 3개 마커 (Tier 1 / Tier 2 / Tier 3)

```
즉시  ◉────────────◯────────────◯
      Tier 1       +2h          +24h
      WP, Blogger  네이버      티스토리
      개인         (예약)       (예약)
```
- 마커: 16px 원, 활성 = primary, 대기 = border
- 연결선: 2px, 활성 구간 = primary, 미진행 = border

### 2.4 BYOC 체인 편집기 (드래그 & 드롭)
**구조**: 수직 리스트, 드래그 핸들 + 우선순위 번호 + CLI 카드

```
┌─[1]──────────────────────────────────────┐
│  ⠿  Claude Code                           │ ← drag handle
│      A1: Pro 계정 ████░░░ 40% (3시간 후)   │
│      A2: Max 계정 ██░░░░░ 22%             │
│      A3: Pro 계정 ███████ 95% ⚠️           │
│  [+ 계정 추가]                             │
└────────────────────────────────────────────┘
┌─[2]──────────────────────────────────────┐
│  ⠿  Codex CLI                             │
│      A1: Plus 계정 █░░░░░ 12%             │
└────────────────────────────────────────────┘
... (3, 4, 5)
```
- 카드: `radius-lg`, 좌측 4px Indigo border
- 드래그 핸들: `text-tertiary`, 6×6 grid 아이콘
- 사용량 진행바: rate limit 잔량 표시. 80%+ → warning amber, 95%+ → error rose
- 빈 슬롯: dashed border + "+ 계정 추가" 버튼

### 2.5 모바일 PWA 홈
**구조**: 어제 발행 카드 그리드 + 오늘 통계 미니 차트

```
┌─────────────────────┐
│  Multi Blog         │
│  안녕하세요, 대표님  │
├─────────────────────┤
│  어제 발행 (3건)     │
│  ┌─────────────┐    │
│  │ AI 가이드    │    │
│  │ 5플랫폼 ✓    │    │
│  │ PV 1,234     │    │
│  └─────────────┘    │
│  ┌─────────────┐    │
│  │ Claude Tips  │    │
│  └─────────────┘    │
├─────────────────────┤
│  오늘 통계 미니      │
│  ▁▃▅▇█▆▄ 차트       │
└─────────────────────┘
```
- 카드 너비: 100% - 32px padding
- 통계 미니: Recharts sparkline

### 2.6 발행 대상 선택 모달
체크박스 5개 + Tier 라디오 + canonical 자동 표시 + 발행 버튼.

### 2.7 멀티 패스 검토 결과 패널 (V1.1)
6개 패스 결과 카드 (구조/SEO/독자/사실/이미지/경쟁).

---

## 3. 화면 인벤토리 (V1)

| # | 화면 | 디바이스 | 우선순위 | 비고 |
|---|------|---------|---------|------|
| S1 | 통합 발행 대시보드 | Desktop | P0 | 메인 |
| S2 | 콘텐츠 에디터 (마크다운 + 미리보기) | Desktop | P0 | TipTap |
| S3 | BYOC 체인 편집기 | Desktop | P0 | dnd-kit |
| S4 | 통합 통계 대시보드 | Desktop | P0 | Recharts |
| S5 | 모바일 PWA 홈 | Mobile | P0 | next-pwa |
| S6 | 발행 대상 선택 모달 | Desktop | P0 | overlay |
| S7 | 설정 (계정·플랫폼 연동) | Desktop | P1 | - |
| S8 | blog-auto import 화면 | Desktop | P1 | 50건 일괄 |
| S9 | 멀티 패스 검토 결과 | Desktop | P1 | V1.1 |

---

## 4. 인터랙션 패턴

### 4.1 발행 진행 애니메이션
- 진행바 채움: 200ms cubic-bezier(0.4, 0, 0.2, 1)
- 완료 시: Lime 배경 fade-in 300ms + 체크 아이콘 scale 100→120→100ms
- 실패 시: Rose shake 200ms

### 4.2 BYOC 드래그 & 드롭
- 드래그 시작: 카드 scale 1.02 + shadow-lg
- 드롭 영역: dashed border + bg alpha
- 드롭 완료: 200ms 정렬 애니메이션

### 4.3 모바일 푸시 알림
- 발행 완료: 토스트 우상단, 3초 후 자동 dismiss
- 봇 차단: 영구 알림, 사용자 직접 dismiss

---

## 5. 접근성 (A11y)

- WCAG 2.1 AA 준수
- 모든 인터랙티브 요소: focus ring 3px Indigo glow
- 색상 단독 정보 전달 금지 (진행바 옆에 % 텍스트 병기)
- 키보드 네비게이션: Tab 순서 명시
- aria-label, aria-live 영역 (발행 진행 상태)
- 모바일 터치 타깃: 최소 44×44px

---

## 6. 모션 원칙

- 모든 트랜지션: 150~300ms (긴 애니메이션 금지)
- Easing: `cubic-bezier(0.4, 0, 0.2, 1)` (Material standard)
- Reduce motion 지원: `prefers-reduced-motion: reduce` 시 모든 애니메이션 instant

---

## 7. 디자인 시스템 자산

| 자산 | 위치 |
|------|------|
| Stitch Project | `projects/14652388482304775067` |
| Stitch Design System | `assets/7708101689804681370` |
| Tauri 앱 | `E:/AI_Programing/blog-auto/MultiBlog/app/` |
| Frontend (V1) | Next.js 14 (마이그레이션 예정, 현재 vanilla TS) |
| 컴포넌트 라이브러리 | shadcn/ui + Radix + Tailwind |
| 아이콘 | Lucide |
| 차트 | Recharts |
| 드래그 | dnd-kit |
| 에디터 | TipTap (ProseMirror) |

---

## 8. Stitch 추출 화면 (✅ 9/9종 완료, 2026-04-08)

> **Stitch 사용 패턴 확정** — `generate_screen_from_text`는 작동하지만 응답 사이즈(80~330KB)가 컨텍스트 한계 초과로 클로드가 직접 받지 못함. 시스템이 자동 저장한 응답 파일에서 jq로 추출 = 유일한 작동 방법.

```bash
# 1. generate 호출 (timeout 메시지 무시)
# 2. ~/.claude/projects/.../tool-results/mcp-stitch-*.txt 자동 저장
# 3. jq 추출
TITLE=$(jq -r '.outputComponents[0].design.screens[0].title' "$FILE")
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
jq -r '.outputComponents[0].design.screens[0].htmlCode.content' "$FILE" > "design/${SLUG}.html"
```

**주의**: 한국어 prompt → title 한국어 → 슬러그 비어버림. 영문 prompt 또는 수동 rename 필수.

### 추출된 화면 7종 (`MultiBlog/design/`)

| # | 파일 | 크기 | 화면 |
|---|------|------|------|
| S1 | `multi-blog-dashboard-main.html` | 18.0 KB | 통합 발행 메인 대시보드 (5 플랫폼 진행바, Tier 타임라인, 통계 카드 3종) |
| S2 | `multi-blog-content-editor.html` | 17.9 KB | 콘텐츠 마크다운 에디터 |
| S3 | `byoc-chain-editor.html` | 19.5 KB | BYOC AI CLI 체인 편집기 (드래그&드롭) |
| S4 | `statistics-dashboard.html` | 22.6 KB | 통합 통계 대시보드 (4 KPI + 차트) |
| S5 | `multi-blog-mobile-home.html` | 15.4 KB | 모바일 PWA 홈 (어제 발행 카드) |
| S6 | `publish-target-modal.html` | 17.6 KB | 발행 대상 선택 모달 (5 체크박스 + Tier 라디오) |
| S7 | `settings-platforms.html` | 16.2 KB | 설정 - 플랫폼 연결 화면 |
| S8 | `blog-import-console.html` | 20.8 KB | blog-auto Import 콘솔 (드래그&드롭 50건 일괄) |
| S9 | `multi-pass-review-results.html` | 18.9 KB | 멀티 패스 검토 결과 패널 (6 패스 카드) |

**총 9종 / 약 180 KB HTML** — 옵시디언 사본 동기화 완료. **DESIGN.md의 9 화면 명세 100% 매칭** ✅

### shadcn/ui 통합 (2026-04-08)
- ✅ `pnpm dlx shadcn@latest init` — Tailwind 4 호환 확인 (`Found Tailwind v4`)
- ✅ 컴포넌트 8종 추가: button, card, progress, dialog, tabs, badge, input, label
- 위치: `app/web/src/components/ui/`
- 다음 라운드: 추출된 9종 HTML을 shadcn 컴포넌트로 변환

## 9. 디자인 다음 단계

- [ ] 추출된 7종 HTML을 Next.js + shadcn/ui React 컴포넌트로 변환 (Tailwind CDN → Tailwind 4)
- [ ] shadcn/ui 컴포넌트 매핑표 (Card/Button/Progress/Tabs/Dialog)
- [ ] Tailwind config에 디자인 토큰 적용 (`tailwind.config.ts`)
- [ ] 다크/라이트 토글 (V1.1)
- [ ] 한국어 폰트 fallback (Pretendard)
- [ ] 추출된 HTML 직접 webview로 띄워 시각 검토 (`open design/multi-blog-dashboard-main.html`)

---

## Appendix: Stitch 디자인 시스템 원본

```json
{
  "displayName": "Multi Blog - Personal Tool",
  "theme": {
    "colorMode": "DARK",
    "headlineFont": "INTER",
    "bodyFont": "INTER",
    "labelFont": "INTER",
    "roundness": "ROUND_TWELVE",
    "customColor": "#4F46E5",
    "colorVariant": "VIBRANT",
    "overridePrimaryColor": "#4F46E5",
    "overrideSecondaryColor": "#84CC16",
    "overrideTertiaryColor": "#0F172A"
  }
}
```
