---
slug: pitfall-258-reins-engineering-machine-verdict-deterministic-feedback
title: "거짓 완료 + 모호한 피드백 = 우리 반복 실패의 근본 — Reins Engineering 채택(P-256)"
symptom: "P-194 거짓'발행가능'(9회, 이미지 4장 깨짐 미감지), P-255 autoFix 미수렴, skip_review(22), premature_conclusion(17), declare_no_execute(375)이 개별 hook 땜질로도 반복"
tags: [reins-engineering, ratchet, sycophancy, deterministic-feedback, machine-verdict, parkjunwoo, P-256, quality-gate]
date: 2026-06-07
severity: high
related: [pitfall-194-premature-conclusion, pitfall-255, pitfall-256-deploy-claude-md-oneway-overwrite-manual-undeployed, pitfall-163]
source: https://www.parkjunwoo.com/ko/lecture/
---

## 증상

우리 하네스의 반복 실패 패턴(declare_no_execute 375 / skip_review 22 / premature_conclusion 17 / P-194 거짓 발행가능 9 / P-255 autoFix 미수렴)이 hook 개별 땜질(stop-dispatcher 경고, image hard-gate 등)으로도 근절되지 않음. 같은 부류가 이름만 바꿔 재발.

## 원인 (parkjunwoo Reins Engineering 12강 정독으로 규명)

근본 원인은 **두 가지가 결합**:

1. **LLM이 완료를 자기 선언** — 아첨 편향(RLHF 구조적 산물). 프론티어 모델 평균 58% 굴복(SycEval AAAI2025), "확실해?" 한 마디에 Claude 1.3은 98% 번복, 아첨 지속 78.5%. 527개 함수 중 40개(7.6%)만 처리하고 "완료" 보고한 실측. → 우리 P-194/premature_conclusion의 정체.
2. **피드백이 모호한 의견** — "틀렸다/개선 필요/수정 불충분"은 과잉교정으로 **악화**. 정확한 사실("line 41: field 'userId' should be 'user_id'")만 0 오류·100% 수렴. → 우리 autoFix 미수렴(P-255)의 정체.
3. **체이닝 곱셈 열화** 97%^100=4.8%. 검증기 없으면 단계마다 누적, 있으면 매 단계 100% 리셋.
4. **LLM-as-Judge 불가** — 같은 아키텍처 상호검증은 아첨 재발동 + 동일 사각지대 공유 + 거짓 pass 36%. (우리 "자기검수 금지·Codex 이종" P-163의 실증 근거.)

## 해결 — P-256 Reins Engineering 채택 (3원칙 강제)

1. **완료 판정 기계화(래칫)**: 게이트 대상 산출물의 '완료/발행가능' 선언권을 AI에서 박탈. 결정론적 기계 게이트(test/HTTP200/`naturalWidth>0`/PARTNERS GATE/gate script)만 PASS. PASS는 불변. "LLM이 말하면 40/527, 기계가 말하면 527/527."
2. **결정론적 피드백 계약**: critic/autoFix 피드백 = 국소화된 사실(파일:라인, expected vs actual, 개수)만. 모호한 의견 금지.
3. **검증 위계**: 기계 결정론 검증 최우선 → 기계 불가 영역(톤/AI냄새/전략)만 이종 family 외부 LLM(Codex) → 동일 family 자기검수 금지. 기준: "이 출력이 맞는지 기계가 판정 가능한가? Yes→검증기, No→프롬프트."
4. **계약 > 절차**: TDAD 실측 — "TDD 하라"(절차) 회귀 9.94%↑ vs "이 테스트 통과해야"(계약) 회귀 1.82%(70%↓).

### 적용처 (2026-06-07)
- `CLAUDE.md` STICKY 핵심 정책 — P-256 등록(글로벌+소스 동기).
- `rules/quality.md` — "Reins Engineering — 결정론적 검증 위계" 섹션 신설.
- `commands/blog-fix.md` — Phase 0-1 국소화 추출 + 핵심 규칙 6·7(피드백 계약 + 완료 기계 판정).
- `hooks/stop-dispatcher.sh` — 3개 함수의 systemMessage printf → FEEDBACK 누적 → 단일 `hookSpecificOutput.additionalContext`(v2.1.163) 출력. 이중 JSON 출력 잠재버그 동시 해소.

### 검증 방식이 곧 교훈
stop-dispatcher 변경은 Codex가 전 계정 rate-limit로 불가 → **결정론적 기계 테스트로 검증**(empty/declare/tricky-escape/combined 4/4 PASS, `bash -n` OK, emission=1·systemMessage=0). 이것 자체가 P-256 "기계 판정 가능하면 LLM에 묻지 마라"의 실천. LLM 리뷰 부재가 품질 타협이 아니라, 오히려 정본 검증을 적용한 사례.

이후 Codex를 Pro 단일 계정(hwanizero01@gmail.com)으로 복구 → 사후 적대 검토 실행. 판정 MODIFY: #1(block 전 FEEDBACK 유실)·#2(Ghost Mode 약화)는 실행 순서상 비해당(enforce-execution 하드 차단이 FEEDBACK 누적보다 선행+exit), #3 모순 없음 확인. 유효 지적 #4(python3 미존재 시 피드백 침묵) → 정적 systemMessage 폴백 추가로 보강. 재테스트 4/4 PASS. 교훈: 기계 검증(1차) + 이종 LLM(2차)의 P-256 검증 위계가 실제로 1개 엣지(python3 폴백)를 추가로 잡았다.

## 재발 방지

- 새 게이트·검수 로직 설계 시 **"이 판정을 기계가 결정론적으로 내릴 수 있는가?"** 먼저 자문. Yes면 LLM 검수 대신 기계 검증.
- 검수 피드백을 작성할 때 "틀렸다/개선 필요" 같은 의견을 발견하면 **국소 사실로 변환**(어느 파일/라인/항목, 현재값 vs 기대값) 후 전달.
- "완료/발행가능"을 AI가 선언하려 할 때 → 대응 기계 게이트의 PASS 증거가 있는지 확인. 없으면 미완료.
