---
date: 2026-04-08
source: https://www.youtube.com/watch?v=Q5_a3B49E8U
channel: Tech Bridge (@TechBridge-KR)
title: Anthropic destroyed the entire Agent Harness
published: 2026-04-05
tags: [harness, anthropic, opus-4.6, planner-generator-evaluator, ablation]
---

# Anthropic이 Agent Harness를 해체했다 — 영상 분석

## 한 줄 요약
> Opus 4.6 등장으로 기존 하네스 요소 대부분이 오버헤드가 됐다. 남은 건 **Planner · Generator · Evaluator** 3개 에이전트뿐.

## Anthropic의 실험 방법
자사 하네스의 각 요소를 **하나씩 제거(ablation)** 하며 영향 측정:
- 기존 프레임워크(BMAD, Jest, SpecKit, Superpowers)는 "모델이 혼자 못 한다"는 **가정** 위에 세워짐
- Opus 4.6에서 그 가정이 **대부분 무너짐**
- 결론: Plan + Generate + Evaluate 3개 에이전트면 충분, 나머지는 "짐"

## 모델 세대별 패러다임 전환

| 요소 | Opus 4.5 이전 | Opus 4.6 이후 |
|------|-------------|-------------|
| Planning | 마이크로 태스크까지 세분화 필수 | 고수준 결과물만 명시 |
| Context 분리 | 필수 (context rot 방지) | 불필요 (1M 윈도우+압축) |
| Context Reset | 긴 작업마다 필요 | 한 세션 연속 실행 가능 |
| Sprint 계약 | 평가자 개입 필수 | Generator 단독 처리 가능 |
| 세부 태스크 분해 | BMAD/SpecKit 필수 | 고수준 가이드로 충분 |

**중요**: 작은 모델(Sonnet/Haiku)은 아직 구식 하네스가 필요. 모델 체급별로 하네스 복잡도가 달라야 함.

## 3-에이전트 구조

### 1. Planner Agent
- ❌ 기술 구현 디테일 금지 (작은 오류가 9단계 뒤로 전파)
- ✅ **제품 레벨 관점** (기능 분해 + User Story)
- ✅ 범위를 크게 잡고 한계를 밀어붙임
- Claude Plan Mode는 "구현 세부" 치우침 → 별도 Planner 에이전트 권장

### 2. Generator Agent
- 계획 명세 수신 → 지속 구현 + Git 연동
- Design 방향 따르기 → 작업 검증 → Evaluator에 넘김

### 3. Evaluator Agent (가장 중요)
- **Generator와 반드시 분리** — 같은 에이전트가 자기 코드 평가하면 "자기 확신 편향"
- "버그가 있다고 가정"하고 비판적으로 검토
- Playwright로 사용자 상호작용 흉내
- **계약 선행**: 구현 전에 Generator와 완료 기준 합의

## Frontend 평가 루브릭 (Anthropic 공식)

| 평가축 | 내용 | Claude 상태 |
|-------|------|-----------|
| Design 일관성 | 화면 통일성 | 약점 |
| **독창성** | "보라색+흰색 그라데이션" 탈출 | **가장 큰 약점** |
| 완성도 | Typography, 간격, 대비율 | 약점 |
| 기능성 | 컴포넌트 UX 역할 | 이미 잘함 |

→ 각 항목에 점수 rubric 부여 → Evaluator는 이 파일을 "정답"으로 삼음

## 실전 권장사항
- **쉬운 길**: GSD 프레임워크 (Plan/Gen/Eval 루프 내장, pass/fail 방식)
- **직접 구축**: Sub-agent 아닌 **Agent Team** (서로 대화 가능)
  - Agent 1: Generator
  - Agent 2: Playwright MCP로 테스트 + 대기/검증
  - 협업하며 완성까지

## JamesClaw 하네스와의 정렬

### 이미 정렬된 부분
- **하네스 v5 pruning** (90→57줄, 5 hook→1 dispatcher) = "Build to Delete" 철학
- **/pipeline-run 11단계** = Planner(1-2) → Generator(3-6) → Evaluator(7-10) 구조
- **외부 모델 검수** (Codex/Antigravity) = Generator≠Evaluator 원칙
- **Stitch 1순위 + DESIGN.md 필수** = "디자인 독창성" 약점 대응

### 다음 진화 방향
1. **Planner 고수준화**: PRD에서 기술 스택 고정 축소, 제품 레벨 중심
2. **Evaluator 자동화**: Playwright MCP + 외부 모델 결합
3. **모델 체급 조건부 하네스**: Sonnet/Haiku 사용 시에만 세부 태스크 분할 활성화
4. **Frontend Rubric 파일화**: design_rubric.md 생성 → Evaluator가 참조하는 "정답 기준"

## 핵심 인사이트
1. **Harness는 모델 종속적** — 몇 달 전 최적이 지금은 제약
2. **개선 = 제거** (ablation study) — 추가가 아닌 빼기
3. **Generator ≠ Evaluator** — 자기 검수 편향 방지
4. **고수준 계획 > 마이크로 태스크** — 강한 모델일수록 여지를 남겨야 함
