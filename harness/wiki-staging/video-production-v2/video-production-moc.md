---
title: "영상 제작 프로젝트 (MOC v2)"
slug: video-production-moc
type: moc
date: 2026-04-28
project: video-production
tags:
  - moc
  - video-production
  - gpt-5.5
  - seedance-2.0
---

# 영상 제작 프로젝트 (MOC v2)

작업 디렉토리: `E:/AI_Programing/영상제작`
레퍼런스 영상: [AI 아스트라 GPT 5.5 + Seedance 2.0](https://www.youtube.com/watch?v=7oN5U0XFhNU)
재작성일: 2026-04-28 (v1 폐기, v2 신규 — 영상 시각 시트 추출 누락 PITFALL-079 반영)

---

## 핵심 자료 (시트 3종 + 워크플로우)

### 1. 시트 템플릿 (영상 핵심 산출물)
- [[aastra-character-sheet-template]] — 9블록 매거진 레이아웃 캐릭터 시트 (서하린 + 해치)
- [[aastra-color-palette]] — HEX 4색 락 룰 (서하린: sky/coral/cream/butter, 해치: turquoise/gold/coral/cream)
- [[aastra-storyboard-sheet-template]] — 7컬럼 표 (#/시간/비주얼/카메라/신/SFX/음악) + 2 frames/sec 룰

### 2. 실행 프롬프트
- [[aastra-master-prompts]] — Copy & Paste 5종 (캐릭터 마스터 시트 ×2, 스토리보드 시트, Seedance 비디오, Suno 음악)

### 3. 통합 워크플로우
- [[aastra-workflow-v2]] — GPT 5.5 + Seedance 2.0 + Suno 2단계 9스텝 파이프라인

---

## 핵심 룰 요약

| 룰 | 내용 | 인용 |
|----|------|------|
| **HEX 락** | 모든 색상 6자리 hex, 어휘 금지 | "파란색이라고만 쓰면 AI가 진한/연한으로 매번 재해석" |
| **미시 디테일** | "체스트 길이 웨이브" 같은 구체 명시 | "롱헤어 쓰면 어깨~허리 사이 매번 흔들림" |
| **마스터 시트 1장** | 생김새/의상/소품/색 모두 한 장 고정 | "이 한 장이 모든 것을 결정" |
| **2 frames/sec** | 시작 프레임 + 끝 프레임 컷마다 명시 | "15초 영상 만들어줘 식 단일 프롬프트는 카메라/타이밍 흐트러짐" |
| **수미상관** | 오프닝 = 클로징 거울 | 경복궁 → 판타지 → 경복궁 |
| **감정 피크 87%** | 영상 길이 87% 지점 클라이맥스 | 2분 영상 → 1분 45초 |
| **오디오 맵핑** | 가야금/해금/대금/첼로 컷별 사전 배치 | "AI 모르면 GPT와 협의" |

---

## 도구 스택

| 단계 | 도구 | 가격 |
|------|------|------|
| 스토리/시트/스토리보드 | ChatGPT GPT-5.5 image-2 (3:4) | Plus $20/월 |
| 영상 생성 | Seedance 2.0 (15초 단위) | fal.ai $0.40/초 |
| 음악 | Suno | $10/월 무제한 |
| 편집 | ffmpeg / Premiere | 자체 |
| 보조 | Claude Opus / Gemini | (별도) |

---

## 현재 PRD와 매핑

`E:/AI_Programing/영상제작/PRD.md` (v2.1) 모듈 ↔ 본 워크플로우 단계:

| PRD 모듈 | 본 워크플로우 |
|----------|---------------|
| `00_character_sheet.py` | 단계 2 — 캐릭터 마스터 시트 (9블록) |
| `01_storyboard_sheet.py` | 단계 5 — 스토리보드 시트 (7컬럼) |
| `02_keyframes.py` | 단계 5 — 시작/끝 프레임 추출 (2fps) |
| `02b_videogen.py` (Seedance) | 단계 7 — 컷별 영상 생성 |
| `02c_videogen_veo.py` (Veo) | 단계 7 폴백 |
| `06_compose.py` | 단계 9 — ffmpeg 편집 |

---

## 작업 상태

- [x] 영상 분석 (자막 + 시각 시트 양쪽)
- [x] 시트 3종 템플릿 작성
- [x] 마스터 프롬프트 5종 추출
- [x] 워크플로우 v2 통합 문서
- [ ] PRD.md v2.2 업데이트 (시트 3종 직접 참조 추가)
- [ ] `00_character_sheet.py` 시트 9블록 명세 반영
- [ ] `01_storyboard_sheet.py` 7컬럼 표 명세 반영
- [ ] 첫 데모 — 서하린 마스터 시트 1장 생성 + 검증

---

## 관련 PITFALL
- pitfall-079 — 영상 튜토리얼 분석 시 시트 템플릿 추출 누락 (본 v2 작업의 직접 원인)
- pitfall-075 — research not applied to PRD (유사 패턴)
- pitfall-076 — image-to-video 단계 누락
- pitfall-036 — 영상 렌더 검증을 메타데이터로만 판정

## 변경 이력
| 날짜 | 변경 | 근거 |
|------|------|------|
| 2026-04-28 | v1 → v2 폐기/신규. 시트 3종 + 프롬프트 5종 + 통합 워크플로우 분리 작성 | 대표님 지적: "캐릭터 시트도 만들지 않았고, 컬러톤도 잡지 않았으며, 스토리보드 시트도 작성하지 않았어" |
