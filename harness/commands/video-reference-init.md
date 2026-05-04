---
description: "신규 영상 프로젝트 부트스트랩 — 해치 검증된 레퍼런스 프로토콜 적용"
user_invocable: true
---

# /video-reference-init — 영상 프로젝트 부트스트랩

## 사용법
- `/video-reference-init <project-name>` — 신규 영상 프로젝트 폴더 생성 + 레퍼런스 프로토콜 + Phase 0 체크리스트
- 출처: 영상제작/해치의 이상한 나라 (2026-04-29~30) PITFALL P-084~087 검증 패턴

## 인자 검증
- `$ARGUMENTS` 비어있으면 즉시 중단 후 보고: "프로젝트명 필요. 사용법: `/video-reference-init <name>`"
- 영문 슬러그 권장 (한글 가능, 공백 무방). 공백은 하이픈 권장.

## 실행 절차

### Step 1: 프로젝트 루트 결정
```bash
PROJECT="$ARGUMENTS"
ROOT="E:/AI_Programing/$PROJECT"
```
이미 존재하면 `[video-reference-init] $ROOT 이미 존재 — 중단` 출력 후 종료.

### Step 2: 폴더 구조 생성
```bash
mkdir -p "$ROOT/references/manuals"
mkdir -p "$ROOT/references/phase0"
mkdir -p "$ROOT/characters"
mkdir -p "$ROOT/storyboards"
mkdir -p "$ROOT/prompts"
mkdir -p "$ROOT/outputs"
```

### Step 3: 템플릿 파일 작성

#### 3a. CLAUDE.md — 프로젝트 룰
경로: `$ROOT/CLAUDE.md`. Write 도구로 다음 내용 그대로 작성 (단, `{PROJECT}` 자리는 실제 프로젝트명으로 치환):

```markdown
# {PROJECT} — Project Rules

## 정체성
영상 프로젝트 {PROJECT}. JamesClaw 글로벌 룰(`~/.claude/CLAUDE.md`) + 영상 레퍼런스 프로토콜 상속.

## 철학
- **검증 우선**: 새 도구는 매뉴얼 정독 후 1컷 테스트 → N컷 진행
- **레퍼런스 충실**: `references/REFERENCE-PROTOCOL.md` 절차 준수
- **자산 누적**: 검증된 프롬프트/시트는 `prompts/`, `characters/`에 보존
- **복제 먼저, 차별화 나중** (P-081)

## Phase 흐름 (각 단계 종료 시 대표님 검토 게이트)
- [ ] **Phase 0** — 도구 결정 + 공식 매뉴얼 정독 (`references/manuals/`, `references/phase0/`)
- [ ] **Phase 1** — 작가 의도/벤치마크 분석 + 캐릭터 마스터 시트 락 (`characters/`)
- [ ] **Phase 2** — 스토리보드 N컷 생성 + 1컷 테스트 게이트 (`storyboards/`, `prompts/`)
- [ ] **Phase 3** — 영상 생성 (1컷 테스트 → N컷)
- [ ] **Phase 4** — 편집/오디오/공개

다음 Phase 자동 진입 금지. 각 단계 산출물 + 다음 Phase 제안 동시 보고.

## 핵심 락 (REFERENCE-PROTOCOL.md 참조)
- 모든 색상 → HEX 코드 강제 (예: `스카이블루 #7CB9E8`)
- 마스터 시트 1장 = 의상/소품/표정/포즈/HEX 팔레트 고정
- 스토리보드 = 초당 2컷, 카메라/액션/효과/음악 표 동시 명시
- 도구 매뉴얼 정독 = 0단계 필수
- 작가 명시 도구 > 자동화 가능 경로 > API 직접 호출 (해치 검증)

## 금지
- 매뉴얼 정독 없이 도구 사용
- 1컷 테스트 없이 N컷 일괄 생성
- 매뉴얼 갭 무차별 적용 (컷별 컨텍스트 분기 필수)
- 캐릭터 시트 없이 영상 생성
- 학습 데이터 cutoff 의존 (현재 시점 대비 도구 신버전 웹 검색 필수)

## 보고 / 커밋
- 한국어 합니다체. 코드/주석은 영어.
- Phase 종료 시 결과물 + 다음 Phase 제안 동시 보고.

## 자율 실행 4조건 (P-086)
다음 4 조건 모두 충족 시 게이트 질문 금지, 즉시 실행:
1. 비용 0 또는 사전 보고된 범위 내
2. 위험 0 (시스템 손상/되돌릴 수 없는 변경 없음)
3. 가역적 (실패 시 즉시 롤백 가능)
4. 외부 자료/도구 출력으로 검증된 사실 기반
```

#### 3b. references/REFERENCE-PROTOCOL.md — 레퍼런스 제작 규칙
경로: `$ROOT/references/REFERENCE-PROTOCOL.md`. 다음 내용 그대로 작성:

```markdown
# 영상 프로젝트 레퍼런스 제작 프로토콜 v1.0

출처: 영상제작/해치의 이상한 나라 (2026-04-29~30) 검증
PITFALL 연동: P-084 (매뉴얼 갭 무차별 적용), P-085 (권한 팝업), P-086 (자율 실행 4조건), P-087 (매뉴얼 정독 우선)

---

## 0. Phase 0 — 도구 정독 (필수)

### 0-1. 도구 후보 작성
프로젝트 시작 즉시:
- 이미지 도구 후보 (ChatGPT UI/API, Nano Banana 2/Pro, Midjourney, gpt-image-2 등)
- 영상 도구 후보 (Seedance, Veo, Runway, Kling, Hailuo 등)
- 편집 도구 (CapCut, Premiere, Resolve 등)
- 오디오 소스 (Suno, BGM 라이브러리, SFX 등)

### 0-2. 매뉴얼 적재
각 도구의 공식 문서를 `references/manuals/{tool-name}.md`에 적재.
- WebFetch 또는 curl로 적재
- 정독 항목: 입력 슬롯, 파라미터 schema, 권장값, 알려진 한계, best practice, 예제 프롬프트
- 정독 결과 요약을 `references/phase0/{tool-name}-summary.md`에 저장

### 0-3. 학습 데이터 cutoff 인지
Knowledge cutoff (Aug 2025) < 현재 시점 시 반드시 웹 검색으로 최신 버전 확인.
- 도구명/모델명 단정 금지 (예: "Nano Banana = Gemini 2.5 Flash" → 사실 2026-02 시점 Nano Banana 2 = Gemini 3.1 Flash가 기본)

---

## 1. 캐릭터 락 (Phase 1)

### 1-1. HEX 코드 강제
색상 표현은 단어로만 쓰지 않고 HEX 코드 동시 명시.
- 나쁜 예: "스카이블루 한복"
- 좋은 예: "스카이블루 #7CB9E8 한복 (chima 색상)"

### 1-2. 마스터 시트 1장
1장의 시트에 다음을 모두 고정:
- 의상 (상의/하의/액세서리)
- 소품 (들고 있는 것, 입고 있는 것)
- 표정 + 포즈 (정면/측면/후면 최소 3종)
- 컬러 팔레트 (HEX)

이 시트는 이후 모든 컷의 reference로 첨부.

### 1-3. 구체 표현
추상 표현 금지. 가능한 한 구체적으로.
- 나쁜 예: "롱헤어"
- 좋은 예: "체스트렝스 웨이브, 가르마 왼쪽, 끝단 살짝 컬"

---

## 2. 스토리보드 (Phase 2)

### 2-1. 초당 2컷 분해
영상 도구에 단순 길이 지정 금지.
N초 영상 = 2N컷 프레임투프레임 시트.

### 2-2. 컷별 표 (의무)
각 컷마다 다음 표 필수:

| 시간 | 카메라 | 액션 | 효과 | 음악/SFX |
|-----|-------|------|------|---------|
| 0:00-0:01 | 클로즈업, 정면 | 캐릭터 등장 | 빛 번짐 | 베이스 드롭 |
| ... | ... | ... | ... | ... |

### 2-3. 오디오 사전 매핑
- 악기 / BPM / 톤 / 감정 피크 위치 사전 결정
- 영상 생성 전 결정 (영상에 맞춰 음악 조정 ✗, 음악에 맞춰 영상 생성 ✓)

### 2-4. 컷별 컨텍스트 분기 (P-084 핵심)
캐릭터의 형태/모드/상태가 컷마다 다르면 reference도 컷별 분리.

예: 해치 프로젝트
- CUT01, CUT08 (석상 컷): protagonist + 석상 reference (살아있는 해치 reference 제외)
- CUT02~07 (살아있는 해치 컷): protagonist + 살아있는 해치 reference

매뉴얼 권장(multi-reference 풀 첨부)을 모든 컷 동일 적용 금지 — 작가 의도 손상.

---

## 3. 도구 선택 우선순위 (해치 검증 결과)

| 우선순위 | 경로 | 의도 충족도 | 자동화 |
|---------|------|------------|--------|
| 1 | 작가/벤치마크 명시 도구 직접 사용 | 92~97% | UI 자동화 가능 |
| 2 | 작가 도구의 자동화 가능 경로 (UI 자동화) | 92% (해치 ChatGPT) | ✅ |
| 3 | API 직접 호출 (자체 프롬프트) | 78% (해치 v2) | ✅ 강력하나 의도 손실 |

작가 도구 무시하고 자체 프롬프트 우선 시 의도 충족도 -14% 손상 (해치 v2 사례).

---

## 4. 검증 게이트

### 4-1. 1컷 테스트 → N컷
N컷 일괄 생성 금지. 1컷 결과를 작가 의도와 매칭 후 N컷 진행.
1컷 결과 비매칭 시: 프롬프트/reference 조정 → 1컷 재테스트 → 매칭 시 N컷.

### 4-2. Vision 검증 (Opus)
생성 결과를 Opus Read로 직접 확인 (HTTP 200 / 파일 생성 사실만으로 검증 완료 판단 금지).
체크리스트:
- 캐릭터 일관성 (5컷 비교 시 핵심 식별자 100% 동일)
- 컷별 컨텍스트 (석상 vs 살아있는 등 분기 정확)
- 작가 의도 매칭률 (목표 90%+)

### 4-3. 외부 모델 교차 검수
주요 결과물 = Codex + GPT-4.1 교차 검수 (Self 검수 금지).

---

## 5. 자동화 도구 경계 (P-085)

| 작업 | 도구 |
|------|------|
| 페이지 내부 (DOM, 버튼, 입력) | claude-in-chrome / expect MCP |
| 브라우저 chrome (탭, 권한 팝업, 다이얼로그) | desktop-control (computer use) |
| OS 알림 / 시스템 다이얼로그 | desktop-control |

자동 다운로드 실패 시 첫 행동: `mcp__desktop-control__computer(action: "get_screenshot")` 으로 전체 화면 점검.

---

## 6. 학습 자료화 (Phase 종료 시)

각 Phase 결과를 다음 형식으로 보존:
- 검증된 프롬프트 → `prompts/{cut-id}-{tool}.txt`
- 비교 분석 → `references/comparison-{topic}.md` (3종 이상 도구/방식 비교)
- PITFALL → gbrain `pitfall-NNN-{slug}` + `D:/jamesclew/harness/pitfalls/`

---

## 변경 이력
| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-04-30 | v1.0 | 해치 프로젝트 검증 기반 초기 정의 |
```

#### 3c. references/PHASE-0-CHECKLIST.md — Phase 0 체크리스트
경로: `$ROOT/references/PHASE-0-CHECKLIST.md`. 다음 내용 그대로 작성:

```markdown
# Phase 0 체크리스트

## 도구 결정
- [ ] 이미지 도구 후보 3개 이상 비교 (1순위 결정 + 백업 2개)
- [ ] 영상 도구 후보 3개 이상 비교 (1순위 결정 + 백업 2개)
- [ ] 편집 도구 결정
- [ ] 오디오 소스 결정 (BGM 라이브러리, Suno, SFX)

## 매뉴얼 정독 (P-087)
- [ ] 선택 도구 공식 문서 → `references/manuals/{tool}.md` 적재
- [ ] 입력 슬롯 / 파라미터 schema 파악
- [ ] 권장값 / 알려진 한계 정리
- [ ] best practice + 예제 프롬프트 보존
- [ ] 정독 결과 요약 → `references/phase0/{tool}-summary.md`

## 작가/벤치마크 자료
- [ ] 작가 PDF/벤치마크 영상 적재 (있다면)
- [ ] 작가 명시 도구 확인
- [ ] 작가 명시 도구 ≠ 자동화 가능 도구일 경우 우선순위 결정 (해치 검증: 작가 도구 우선)

## 비용 점검
- [ ] 도구별 비용 산출 (1컷 / N컷 / 영상 1분)
- [ ] 1컷 테스트 비용 vs N컷 비용
- [ ] 대표님 사전 승인 필요 임계값 설정 (예: 1회 호출 ₩10,000+ 시 사전 승인)

## 학습 데이터 cutoff 점검
- [ ] knowledge cutoff < 현재 시점 → 웹 검색으로 최신 버전 확인
- [ ] 도구명 / 모델명 단정 금지 (예: 자칫 "Gemini 2.5 Flash" 단정 → 실제 "Nano Banana 2 = 3.1 Flash")

## Phase 1 진입 조건
모든 [ ] 체크 완료 + 대표님 검토 게이트 통과 → Phase 1 진입.
Phase 1: 캐릭터 마스터 시트 작성 + HEX 락 + 구체 표현 적용.
```

#### 3d. .gitignore
경로: `$ROOT/.gitignore`. 다음 내용 그대로 작성:

```
outputs/
.env
.env.*
*.log
.DS_Store
Thumbs.db
```

#### 3e. README.md (간결)
경로: `$ROOT/README.md`. 다음 내용 그대로 작성 (단 `{PROJECT}` 치환):

```markdown
# {PROJECT}

영상 프로젝트. 레퍼런스 프로토콜 v1.0 적용.

## 시작점
1. `CLAUDE.md` — 프로젝트 룰 정독
2. `references/REFERENCE-PROTOCOL.md` — 검증 절차
3. `references/PHASE-0-CHECKLIST.md` — Phase 0 체크리스트
4. Phase 0 진입 → 도구 결정 + 매뉴얼 정독

## 디렉토리
- `references/manuals/` — 도구 공식 문서
- `references/phase0/` — Phase 0 정독 노트
- `characters/` — 마스터 캐릭터 시트
- `storyboards/` — 프레임투프레임 시트
- `prompts/` — 검증된 프롬프트
- `outputs/` — 생성 결과 (gitignore)
```

### Step 4: 보고 출력
다음 형식으로 출력:

```
[video-reference-init 완료]
프로젝트: {PROJECT}
경로: E:/AI_Programing/{PROJECT}/

생성 파일:
- CLAUDE.md (프로젝트 룰)
- references/REFERENCE-PROTOCOL.md (검증 절차 v1.0)
- references/PHASE-0-CHECKLIST.md
- README.md
- .gitignore
- 폴더 6종 (references/manuals, references/phase0, characters, storyboards, prompts, outputs)

다음 단계 — Phase 0:
1. 영상/이미지/편집/오디오 도구 후보 결정
2. 선택 도구 공식 매뉴얼을 references/manuals/에 적재
3. 작가/벤치마크 자료 유무 확인
4. 비용 임계값 결정

대표님 결정 필요:
- 프로젝트 주제 / 톤 / 길이 / 플랫폼 (쇼츠/롱폼)
- 도구 후보 (해치 검증: ChatGPT UI + Seedance 추천)
```

## 전제 조건
- `E:/AI_Programing/` 경로 존재
- Write 도구 사용 가능
- 한국어 파일명 처리 가능 (Windows Git Bash UTF-8)

## 주의사항
- 기존 프로젝트 폴더 덮어쓰기 금지 — Step 1에서 존재 확인 후 중단
- `{PROJECT}` 자리 치환 누락 금지 — Write 호출 시 검증
- 템플릿 작성 후 폴더 구조 ls로 검증 필수
- gbrain 자동 import는 하지 않음 (프로젝트 시작 직후엔 인덱스 가치 낮음). Phase 1 진입 시 또는 첫 Phase 종료 시 수동 import.
