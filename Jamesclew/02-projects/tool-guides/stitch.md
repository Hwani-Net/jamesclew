# Stitch MCP 사용 가이드

> 버전: @_davideast/stitch-mcp v0.5.0 | Stitch 플랫폼: March 2026 업데이트
> 최종 조사: 2026-04-07 | 근거: npm README + Perplexity 10개 소스 분석

## 개요
Google Stitch (stitch.withgoogle.com) — AI 네이티브 소프트웨어 디자인 캔버스.
텍스트/이미지/음성 → 고충실도 UI 디자인 + 프로덕션 코드 생성.
2025-05 Google I/O 런칭 → 2025-12 Gemini 3 + 프로토타입 → 2026-03 무한 캔버스 + 음성 + 바이브 디자인.

**핵심**: MCP는 번들 gcloud를 사용 (시스템 gcloud와 별개). `STITCH_USE_SYSTEM_GCLOUD=1` 필수.

---

## Stitch 플랫폼 전체 기능 (2026-03 기준)

### 1. 텍스트 → UI 생성
- 자연어로 앱 UI 설명 → 수초 내 완전한 레이아웃 생성
- Standard 모드 (Gemini 2.5 Flash): 빠른 반복, 월 350회
- Experimental 모드 (Gemini 2.5 Pro → 3): 고충실도, 이미지 입력 지원, 월 50~200회
- 한 번에 최대 5개 연결 스크린 생성 가능

### 2. 이미지 → UI 변환 (Experimental 모드)
- 손그림 스케치, 와이어프레임, 스크린샷, 참고 디자인 업로드
- AI가 레이아웃 구조, 컴포넌트 배치, 상대 크기를 해석하여 디지털 UI 생성
- **활용**: 화이트보드 사진 → 디지털 목업 즉시 변환

### 3. 바이브 디자인 (Vibe Design, 2026-03)
- 와이어프레임 대신 **비즈니스 목표, 사용자 감정, 영감**을 설명
- "차분하고 정돈된 느낌의 프로젝트 관리 도구" → 여러 디자인 방향 자동 생성
- 넓게 탐색 후 수렴하는 디자인 프로세스

### 4. AI 네이티브 무한 캔버스 (2026-03)
- 이미지, 텍스트, 코드 스니펫, 브랜드 에셋을 캔버스에 드래그
- AI가 모든 컨텍스트를 참조하여 디자인 생성
- 초기 아이디어 → 작동하는 프로토타입까지 하나의 캔버스에서

### 5. 디자인 에이전트 + 에이전트 매니저 (2026-03)
- 프로젝트 전체 진화를 추론하는 AI 에이전트
- 개선 사항 자동 제안, 비주얼 랭귀지에 맞는 변형 생성
- 레이아웃을 목표 대비 비평, 다음 스크린 자동 제안
- **에이전트 매니저**: 여러 디자인 탐색을 병렬 실행 + 비교

### 6. 인스턴트 프로토타이핑 (2025-12~)
- 스크린 연결 → "Play" 클릭 → 클릭 가능한 인터랙티브 프로토타입
- 버튼 클릭 시 다음 논리적 스크린 자동 생성
- "Sign Up" 버튼 → 확인 페이지 자동 생성
- InVision, Figma 프로토타이핑과 직접 경쟁

### 7. 음성 캔버스 (Voice Canvas, 2026-03)
- Gemini Live 기반, 캔버스에 직접 말로 지시
- "메뉴 레이아웃 3가지 보여줘" → 실시간 생성
- "더 어두운 팔레트로" → 즉시 업데이트
- 디자인 크리틱, 인터뷰, 실시간 수정 가능

### 8. 직접 편집 (Direct Edits, 2026-03)
- 텍스트 클릭하여 직접 수정
- 이미지 교체
- 간격/스타일 조정
- 여러 요소 일괄 편집 (Shift+클릭)

### 9. DESIGN.md 디자인 시스템 (2026-03)
- **URL에서 디자인 시스템 자동 추출** (색상, 타이포, 간격, 컴포넌트)
- 마크다운 파일(DESIGN.md)로 저장 → 프로젝트 간 이동 가능
- AI 에이전트가 읽을 수 있는 형식 → Figma, React, AI Studio 호환
- 기존 브랜드 사이트 → DESIGN.md 추출 → 새 프로젝트에 적용

### 10. 변형 생성 (Variants)
- 기존 스크린에서 레이아웃/색상/폰트/콘텐츠 변형
- REFINE (미세조정) / EXPLORE (탐색) / REIMAGINE (완전 재해석)
- 클라이언트에게 빠르게 여러 방향 제시

### 11. 내보내기 (Export)
- **Figma**: Auto Layout 보존, 편집 가능 레이어, 1-click 복사
- **HTML/CSS**: 시맨틱 HTML, 모던 CSS, 반응형
- **Tailwind CSS**: 유틸리티 퍼스트 클래스
- **React/JSX**: 컴포넌트 기반 코드
- **AI Studio**: Google AI 생태계 연동
- **MCP 서버/SDK**: 코딩 에이전트 연동 (Claude Code, Gemini CLI, Codex 등)

### 12. 리디자인 에이전트 (Redesign Agent, 2026-03)
- 기존 사이트를 수초 내 변환
- URL 입력 → 새로운 디자인으로 재생성

### 13. 생성 한도
- Standard 모드: 월 350회
- Experimental 모드: 월 50~200회
- 현재 완전 무료 (2026 후반 유료 전환 예상)

---

## MCP 인증 방법 (우선순위순)

### 1. 시스템 gcloud 사용 (검증됨, 현재 사용 중) ⭐
```bash
gcloud config set account hwanizero01@gmail.com
gcloud config set project bite-log-app
```
```
claude mcp add stitch -s user -e STITCH_USE_SYSTEM_GCLOUD=1 -- npx -y @_davideast/stitch-mcp proxy
```
- **`STITCH_USE_SYSTEM_GCLOUD=1` 필수** (없으면 번들 gcloud → 계정 불일치)
- 시스템 gcloud 계정 = Stitch 웹 계정이어야 함
- 2026-04-07 검증: hwanizero01@gmail.com + bite-log-app → 성공

### 2. init 위저드 (공식 추천, 대화형)
```bash
npx @_davideast/stitch-mcp init
```
- 대화형 위저드: gcloud 설치, OAuth, 프로젝트 연결 자동
- **번들 gcloud**에 인증 저장 (시스템 gcloud와 별개!)
- 리셋: `npx @_davideast/stitch-mcp logout --force --clear-config`

### 3. API 키 (간편하지만 계정 범위 고정)
```
claude mcp add stitch -s user -e STITCH_API_KEY=AQ.xxx... -- npx -y @_davideast/stitch-mcp proxy
```
- API 키 발급 계정의 프로젝트만 접근 가능
- 다른 계정 프로젝트 접근 불가

---

## 환경변수 전체 목록

| 변수 | 설명 |
|------|------|
| `STITCH_API_KEY` | API 키 직접 인증 (OAuth 건너뜀) |
| `STITCH_ACCESS_TOKEN` | 기존 액세스 토큰 |
| `STITCH_USE_SYSTEM_GCLOUD` | 시스템 gcloud 사용 (번들 대신) ⭐ |
| `STITCH_PROJECT_ID` | 프로젝트 ID 오버라이드 |
| `GOOGLE_CLOUD_PROJECT` | 대안 프로젝트 ID |
| `STITCH_HOST` | 커스텀 Stitch API 엔드포인트 |

---

## CLI 명령어

| 명령 | 설명 |
|------|------|
| `init` | 인증 + gcloud + MCP 클라이언트 설정 위저드 |
| `doctor` | 설정 건강 체크 (--verbose로 상세) |
| `logout` | 인증 취소 (--force --clear-config 완전 초기화) |
| `serve -p <id>` | 프로젝트 스크린을 로컬 Vite 서버로 미리보기 |
| `screens -p <id>` | 터미널에서 스크린 브라우징 |
| `view` | 대화형 리소스 브라우저 (c=복사, s=미리보기, o=Stitch열기) |
| `site -p <id>` | 스크린을 Astro 프로젝트로 빌드 |
| `snapshot` | 스크린 상태를 파일로 저장 |
| `tool [name]` | CLI에서 MCP 도구 직접 호출 (-s로 스키마 확인) |
| `proxy` | MCP 프록시 서버 (에이전트용) |

---

## MCP 도구 (proxy 모드)

### Stitch API 도구
| 도구 | 설명 | 주의사항 |
|------|------|---------|
| `list_projects` | 프로젝트 목록 (view=owned/shared) | |
| `get_project` | 프로젝트 상세 + screenInstances | |
| `create_project` | 새 프로젝트 생성 | |
| `list_screens` | 프로젝트 내 스크린 목록 | |
| `get_screen` | 스크린 상세 | |
| `generate_screen_from_text` | 텍스트→디자인 생성 | **수분 소요, 재시도 금지** |
| `edit_screens` | 기존 스크린 수정 | **수분 소요, 재시도 금지** |
| `generate_variants` | 변형 생성 | creativeRange: REFINE/EXPLORE/REIMAGINE |
| `create_design_system` | 디자인 시스템 생성 | **반드시 update 후속 호출** |
| `update_design_system` | 디자인 시스템 업데이트/적용 | |
| `list_design_systems` | 디자인 시스템 목록 | |
| `apply_design_system` | 스크린에 디자인 시스템 적용 | **screenId 아닌 instance id 사용** |
| `fetch_screen_code` | 스크린 HTML 코드 다운로드 | |
| `fetch_screen_image` | 스크린 프리뷰 이미지 | |

### 가상 도구 (proxy 전용)
| 도구 | 설명 |
|------|------|
| `build_site` | 스크린→라우트 매핑→사이트 빌드, HTML 반환 |
| `get_screen_code` | 스크린 조회 + HTML 다운로드 (조합) |
| `get_screen_image` | 스크린 조회 + 스크린샷 base64 (조합) |

---

## 워크플로우 (사용자 개입 없는 자율 루프)

```
[초기 설정]
1. gcloud config set account/project → MCP 등록 (STITCH_USE_SYSTEM_GCLOUD=1)

[디자인 생성] — MCP 사용
2. create_project → projectId
3. create_design_system → update_design_system (필수 후속)
4. generate_screen_from_text → screenId (수분 대기)

[디자인 수정/반복] — Computer-use (desktop-control) 사용
5. Stitch 웹(stitch.withgoogle.com)을 desktop-control로 직접 조작
6. 스크린샷으로 현재 상태 확인 → Direct Edits로 미세조정
7. 디자인 에이전트, 변형 생성 등 웹 전체 기능 활용
8. 10회+ 자율 수정 루프 (외부 모델 검수 포함)
   - 구조 변경: MCP edit_screens 또는 generate_variants
   - 세부 미세조정: desktop-control로 Stitch 웹에서 직접 편집
   - 매 라운드 스크린샷 비교 → 개선점 식별 → 수정 반복

[승인 프로세스]
9. fetch_screen_image → 텔레그램 전송
10. stitch_approval_pending = "pending"
11. 대표님 승인/수정지시까지 추가 생성/코드 적용 금지
12. 수정지시 시 → 5번으로 돌아가 자율 수정 루프 재개

[코드 적용] — MCP 사용
13. 승인 후 fetch_screen_code → HTML 확보
14. page.tsx에 적용 (Tailwind 클래스 변환)
```

### 도구 역할 분담
| 단계 | 도구 | 이유 |
|------|------|------|
| 초안 생성 | MCP | 대규모 생성은 API가 효율적 |
| 디자인 수정/반복 | desktop-control | 시각 피드백 + 웹 전체 기능 접근 |
| 구조 변경 | MCP edit_screens | 텍스트 프롬프트로 대규모 변경 |
| 코드 추출 | MCP fetch_screen_code | API 직접 호출이 빠름 |
| 프로토타이핑 | desktop-control | 웹 전용 기능 |

### 사용자 개입 시점
- **디자인 최종 승인** 1회만 (텔레그램으로 스크린샷 전송 → 승인/수정지시)
- 그 외 전 과정은 에이전트 자율 실행

---

## Stitch 웹 vs MCP 기능 비교

| 기능 | Stitch 웹 | MCP |
|------|-----------|-----|
| 텍스트→UI 생성 | ✅ | ✅ generate_screen_from_text |
| 이미지→UI | ✅ (Experimental) | ❌ (이미지 업로드 불가) |
| 바이브 디자인 | ✅ | ✅ (프롬프트로 대체) |
| 무한 캔버스 | ✅ | ❌ (웹 전용) |
| 디자인 에이전트 | ✅ | ❌ (웹 전용) |
| 에이전트 매니저 | ✅ | ❌ (웹 전용) |
| 프로토타이핑 | ✅ (Play 버튼) | ❌ (웹 전용) |
| 음성 캔버스 | ✅ | ❌ (웹 전용) |
| 직접 편집 | ✅ | ✅ edit_screens |
| DESIGN.md | ✅ (추출/가져오기) | ✅ create/update_design_system |
| 변형 생성 | ✅ | ✅ generate_variants |
| Figma 내보내기 | ✅ | ❌ |
| HTML/CSS 코드 | ✅ | ✅ fetch_screen_code |
| 리디자인 에이전트 | ✅ | ❌ |

**결론**: MCP는 생성/수정/코드 추출에 적합. 프로토타이핑, 음성, 캔버스 등 고급 기능은 웹에서 직접 사용.

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| 403 Permission Denied | 계정/프로젝트 불일치 | `STITCH_USE_SYSTEM_GCLOUD=1` + 올바른 계정 |
| Stitch 웹과 프로젝트 불일치 | 번들 gcloud ≠ 시스템 gcloud | `STITCH_USE_SYSTEM_GCLOUD=1` |
| list_projects 빈 결과 | 다른 계정 인증 | gcloud config set account 확인 |
| generate 실패 | 수분 소요 정상 | 재시도 금지. get_screen으로 나중에 확인 |
| API 키로 프로젝트 안 보임 | 키 발급 계정 ≠ 웹 계정 | 시스템 gcloud 방식으로 전환 |
| Project: 잘못된 프로젝트명 표시 | gcloud config project 불일치 | gcloud config set project 재설정 |

---

## 흔한 실수 (PITFALLS)
- ❌ 시스템 gcloud = MCP gcloud라고 가정 (번들은 별개, `STITCH_USE_SYSTEM_GCLOUD=1` 필수)
- ❌ `GOOGLE_CLOUD_PROJECT`만 설정하고 인증은 다른 계정
- ❌ create_design_system 후 update_design_system 빼먹기
- ❌ generate 실패 시 즉시 재시도 (수분 대기 필요)
- ❌ apply_design_system에 screenId 사용 (screen instance id 필요)
- ❌ 승인 전 추가 화면 생성 (토큰 낭비)
- ❌ 웹 전용 기능(프로토타입, 음성, 캔버스)을 MCP로 시도

---

## BiteLog 프로젝트 컨텍스트
- Stitch 웹 계정: hwanizero01@gmail.com
- GCP 프로젝트: bite-log-app
- MCP 연결: `STITCH_USE_SYSTEM_GCLOUD=1` + gcloud account=hwanizero01
- 프로젝트: BiteLog v2 Redesign (11448591754768904363)
- 스타일: 다크, 인텔리전스 터미널, 프리미엄 낚시 앱
- 브랜드 컬러: #c9a84c (gold), #0a84ff (blue)
- 디바이스: MOBILE 우선

## 핵심 교훈 (2026-04-07)
- 번들 gcloud ≠ 시스템 gcloud → `STITCH_USE_SYSTEM_GCLOUD=1` 필수
- API 키는 발급 계정 범위만 접근 가능
- gcloud 계정 + 프로젝트가 Stitch 웹과 일치해야 함
- MCP는 생성/수정/코드 추출용. 고급 기능은 Stitch 웹에서.
