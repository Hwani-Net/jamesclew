# Stitch Design Reference — MotionSites Premium Hero Patterns

출처: obsidian://open?vault=Obsidian-Vault&file=06-raw%2FMotionSites%20%E2%80%94%20Premium%20Hero%20Prompts
등록일: 2026-04-18

## 사용 규칙
**Stitch로 화면 생성 전 반드시 이 파일 참조.**
아래 패턴을 Stitch 프롬프트에 명시적으로 포함할 것.

---

## 핵심 MotionSites 디자인 패턴

### 1. 배경 (Background)
- **기본**: 순수 블랙 `#050508` 또는 딥 네이비 `#0A0E1A`
- **텍스처 선택지**:
  - 세로줄 패턴 (AI Automation 스타일): `repeating-linear-gradient(to right, rgba(255,255,255,0.03) 0px, rgba(255,255,255,0.03) 1px, transparent 1px, transparent 40px)`
  - 파티클 그리드
  - 오로라 웨이브 (하단 accent color glow)
- **절대 금지**: 보라색+핑크 그라데이션, blur circle 장식 (AI 클리셰)

### 2. Hero 타이포그래피
- **크기**: Display 80px+, weight 700-800
- **믹스 패턴**: Bold sans + Italic serif 혼합 (예: "Automate *repetitive*")
- **구조**:
  ```
  [Pill badge] "New: Real-time Pattern Detection →"
  [H1 Line 1] Very Large Bold Text
  [H1 Line 2] *Italic accent word* in brand color
  [Subtitle] 1-2줄 설명, muted color, 1rem
  [CTA pair] [Filled button] [Ghost button]
  ```

### 3. 대시보드 목업 플로팅
- Hero 텍스트 아래에 실제 제품 스크린샷 또는 목업 플로팅
- 상단 페이드 (`mask-image: linear-gradient(to bottom, transparent 0%, black 20%)`)
- 슬라이트 perspective tilt (rotateX 5-8deg)
- 테두리: `1px solid rgba(255,255,255,0.1)`

### 4. CTA 버튼 쌍
- Primary: `background: #F59E0B; color: #000; border-radius: 8px; padding: 12px 24px; font-weight: 600`
- Secondary: `background: transparent; border: 1px solid rgba(255,255,255,0.2); color: #fff`
- Hover: primary → `brightness(1.1)`, secondary → `background: rgba(255,255,255,0.05)`

### 5. Pill Badge (상단 신규 기능 알림)
```html
<span style="background: rgba(245,158,11,0.15); border: 1px solid rgba(245,158,11,0.3);
             color: #F59E0B; padding: 4px 12px; border-radius: 999px; font-size: 0.75rem">
  ✦ New: Real-time failure pattern detection →
</span>
```

### 6. 네비게이션 (Top Nav)
- 배경: `rgba(5,5,8,0.8)` + `backdrop-filter: blur(12px)`
- 로고 좌측, 링크 중앙, Sign In + CTA 우측
- 링크 hover: amber underline

### 7. Trust Signal (Logo Bar)
- Hero 아래 "Trusted by teams at..." + 그레이스케일 로고들
- `opacity: 0.4` → hover `opacity: 0.7`

---

## AgentLens 전용 적용 패턴

| 요소 | MotionSites 원본 | AgentLens 적용 |
|------|-----------------|----------------|
| 3D 오브젝트 | 보라 글로브, 오로라 | Amber 데이터 네트워크 그래프 or 히트맵 구체 |
| 배경 텍스처 | 세로줄 (AI Automation) | 세로줄 + 미세 amber 글로우 |
| Pill badge | "New AI Automation Ally" | "✦ New: Real-time failure pattern detection" |
| Dashboard mockup | 대시보드 플로팅 | AgentLens Overview Dashboard 스크린샷 |
| CTA | Violet filled | Amber filled (#F59E0B) |

---

## Stitch 프롬프트 삽입 템플릿

새 화면 생성 시 다음 블록을 프롬프트 상단에 포함:

```
DESIGN REFERENCE — MotionSites Premium Hero Style:
- Background: Pure black #050508 with subtle vertical line texture
- Typography: Extra-large (80px+) bold + italic serif mix, white text
- Hero: Pill badge (amber) + 2-line headline + subtitle + CTA pair
- Product mockup: Dashboard screenshot floating below hero with top fade
- CTA: Amber filled (#F59E0B) + ghost button pair
- NO purple gradients, NO blur circles, NO generic icons only
- Vertical line texture: repeating-linear-gradient pattern
- Bottom aurora: amber/orange glow wave at bottom edge
```

---

## 실제 추출된 무료 프롬프트 (2026-04-18, 39개 중 핵심 4개)

### [1] AI Automation Hero — AI/SaaS 대표 패턴 (AgentLens 직접 참조)

```
Create a full-screen hero section with the following exact specifications:

Layout & Structure:
- Full viewport height (h-screen), full width, relative positioning with overflow-hidden
- Background color: #070612 (dark purple-black)
- Content aligned to the left side, vertically centered
- Max-width container (max-w-7xl) with horizontal padding (px-6 lg:px-12)

Badge (top element):
- Pill-shaped badge with rounded-full, border border-white/20, backdrop-blur-sm
- Contains a Sparkles icon (lucide-react, w-3 h-3, text-white/80)
- Text: "New AI Automation Ally" in text-sm font-medium text-white/80
- Animated with blur-in effect (0.6s duration, no delay)

Main Heading:
- Three lines: "Unlock the Power of AI" / "for Your" / "Business." (serif italic)
- Font sizes: text-4xl md:text-5xl lg:text-6xl, font-medium, leading-tight lg:leading-[1.2]
- Each word animates with staggered split-text (0.08s delay, y:40->0, opacity:0->1)

Subtitle:
- text-white/80, text-lg, max-w-xl, leading-relaxed

CTA Buttons:
- Primary: bg-foreground (white), text-background (dark), rounded-full px-5 py-3 + ArrowRight icon
- Secondary: bg-white/20 backdrop-blur-sm, rounded-full px-8 py-3, white text

Z-index layering: Video z-0, Bottom gradient z-10, Content z-20
```

**AgentLens 적용**: Badge 텍스트 → "✦ New: Real-time failure pattern detection", 배경 → `#050508`, Primary CTA → Amber `#F59E0B`

---

### [2] Nexora Automation — SaaS with Floating Dashboard Mockup

```
Fonts: Instrument Serif (display, italic) + Inter (body)
Background: #050508 (pure dark), fullscreen video loop
Badge: "Now with GPT-5 support ✨" — rounded-full, border-border, bg-background, px-4 py-1.5
Headline: "The Future of Smarter Automation" — text-[5rem], leading-[0.95], the word "Smarter" in Instrument Serif italic

Dashboard Preview (frosted glass wrapper):
  background: rgba(255,255,255,0.4); border: 1px solid rgba(255,255,255,0.5);
  boxShadow: 0 25px 80px -12px rgba(0,0,0,0.08);
  mt-8, max-w-5xl, rounded-2xl, overflow-hidden, p-4
  Contains: Top bar (logo+search+CTA), Sidebar (nav items), Main content (KPI cards+chart+table)

Animations: Framer Motion fade-up from y:16, staggered 0.1s per element
```

**AgentLens 적용**: Dashboard mockup → AgentLens Overview Dashboard (Heatmap + KPI cards), 배경 → `#050508` + 세로줄 텍스처

---

### [3] Synapse Dark Hero — Pure Black with Glass Nav

```
Background: solid black #000000
Navbar: Fixed, blurred glass effect (backdrop-blur)
Logo: "Synapse" font-medium tracking-tight white
Hero Badges: Row of 3 glass-effect badges "Integrated with" + Icon
Headline: "Where Innovation Meets Execution" (~80px, tight tracking, fade-in)
Buttons:
  - "Get Started for Free" (solid black bg, white border)
  - "Let's Get Connected" (transparent glass style)
Logo Marquee: grayscale 40% opacity logos at bottom
```

---

### [4] Neuralyn — Analytics SaaS Dark Theme

```
Background: 0 0% 0% (pure black)
Fonts: Inter (400-700, body/UI) + Instrument Serif (400 italic, accent word)
Tag pill: liquid-glass styled, "New" badge (white bg, black text) + "Say Hello to Corewave v3.2"
Title: text-5xl md:text-7xl, tracking-[-2px], font-medium, leading-tight
  "Your Insights." / "One Clear Overview." — "Overview" in Instrument Serif italic
Navbar: px-8 md:px-28, "Sign In" = solid white bg (bg-foreground), black text, rounded-lg
```

---

## Stitch 프롬프트 삽입 템플릿 (업데이트됨)

새 화면 생성 시 다음 블록을 프롬프트 상단에 포함:

```
DESIGN REFERENCE — MotionSites Premium Hero Style (from extracted free prompts):
- Background: #050508 (dark) with repeating-linear-gradient vertical line texture (40px pitch, rgba(255,255,255,0.03))
- Typography: text-5xl→text-7xl, font-medium, Instrument Serif italic for accent word, Inter for body
- Pill badge: border-white/20, backdrop-blur-sm, Sparkles icon, "✦ New: Real-time failure pattern detection"
- Content layout: LEFT-aligned, vertically centered, max-w-7xl container
- CTA pair: Amber filled (#F59E0B, rounded-full, dark text) + glass ghost (bg-white/10, border-white/20)
- Dashboard mockup: frosted glass wrapper (rgba(255,255,255,0.05), border rgba(255,255,255,0.1)), floating below hero
- Bottom aurora: amber/orange glow wave at bottom edge (0 0 120px 40px rgba(245,158,11,0.15))
- NO purple gradients, NO blur circles, NO indigo/teal accent colors
- Logo marquee: grayscale 0.4 opacity, "Trusted by teams at..." text above
```

---

## 레퍼런스 이미지 경로
로컬 캐시: `C:/Users/AIcreator/AppData/Local/Temp/motionsites/`
- `finlytic-ai.png` — purple globe + dashboard mockup
- `ai-automation.png` — black vertical lines, minimal (AI Automation Hero 원본)
- `nexora.png` — nature bg + app mockup (Nexora Automation 원본)
- `grow-ai.png` — deep black + blue aurora wave
