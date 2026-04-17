---
description: "공모전 아이디어 기획→검증→고도화→제출 파이프라인"
argument-hint: "[공모전URL] [과제설명서PDF...]"
---

# /contest-idea — 공모전 아이디어 파이프라인

공모전 사이트 분석 → 과제 파악 → 초안 작성 → 출처 검증 → Agent Teams×Ralph Loop 고도화 → 제출 폼 데이터 생성 → 첨부 구조도 생성

## 절차

### 1. 공모전 분석
- 사이트 WebFetch로 공모 개요 파악
- 공고문 PDF 분석 (과제 목록, 심사기준, 일정, 상금)
- 과제설명서 PDF 분석 + **참고자료 URL 자율 방문 검증** (P-021)

### 2. 초안 작성
- 대표님 경험/자산 매칭 분석
- Sonnet 서브에이전트 병렬로 각 아이디어 초안 (2000자 내외)
- 익명화 원칙 적용 (시스템명/개인명 금지)

### 3. 출처 리서치
- Perplexity search로 각 아이디어별 근거 데이터 수집
- 현재 연도 기준 최신 데이터 확인 (P-014)
- 본문 내 괄호 인용 + 문서 끝 참고문헌 섹션

### 4. 외부 모델 검증
- copilot-api (GPT-4.1/GPT-5.4/Gemini 3.1 Pro) 중 2개+ 모델로 채점
- Perplexity는 검색 도구이지 검증 모델이 아님에 주의

### 5. Agent Teams × Ralph Loop 고도화
- TeamCreate: Attacker, Defender, Innovator, Judge 4역할
- Ralph Loop: max-iterations 10~15, completion-promise "ALLPASS"
- 4축(문제해결/실현/독창/활용) 모두 8점 이상 = PASS
- 혁신 사고(First Principles, 10x) 적용

### 6. 제출 폼 데이터 생성
- 홈페이지 제출 폼 구조 직접 확인 (데스크톱 제어 또는 브라우저)
- 글자수 제한에 맞춰 압축 (공백·특수문자 포함 카운트)
- Python으로 정확한 글자수 검증

### 7. 첨부 구조도 생성
- HTML+CSS + expect MCP(mcp__expect__screenshot) 방식 (Apple Keynote 발표 수준)
- 또는 Stitch MCP (앱 UI용)
- Vision으로 직접 품질 검증 후 보고 (P-024)

## 주의사항
- 시간 판단은 대표님 영역 (P-023)
- 대표님에게 떠넘기기 전에 "내가 직접 할 수 있는가?" 자문 (P-025)
- 서브에이전트 결과물은 반드시 Vision 검증 (P-024)
- 검증 프로세스는 자율적으로 더 나은 방법을 선제 제안 (P-022)
