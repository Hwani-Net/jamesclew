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

## 레퍼런스 이미지 경로
로컬 캐시: `C:/Users/AIcreator/AppData/Local/Temp/motionsites/`
- `finlytic-ai.png` — purple globe + dashboard mockup
- `ai-automation.png` — black vertical lines, minimal
- `nexora.png` — nature bg + app mockup
- `grow-ai.png` — deep black + blue aurora wave
