---
name: Stop hook 오감지 — 조건부 미래·부정 선언·세션 종료·위험 확인 구분 누락
description: enforce-execution.sh가 "조건부 미래 선언"(예 "지시 주시면 진행하겠습니다")을 즉시 실행 위반으로 오감지. "push는 지시 후"처럼 위험 확인 요청도 Pattern 2에서 block당함.
type: pitfall
tags: [hook, stop-hook, ghost-mode, false-positive, enforce-execution]
severity: medium
date: 2026-04-23
---

## 증상

1. **조건부 미래 선언 오감지**: "push는 별도 지시 있으실 때 진행하겠습니다" → Pattern 1이 `진행하겠` 매칭 → `{"decision":"block","reason":"선언-미실행 감지..."}`.
2. **부정 선언 오감지**: "진행하지 않겠습니다" → `않겠습니다`도 `하겠습니다` suffix 매칭 가능.
3. **세션 종료 맥락 오감지**: "마무리 완료. push는 별도 지시 시" 같이 종료 보고에 섞인 미래 시제도 block.
4. **위험 확인 오감지**: `Executing actions with care` 룰에 따라 파괴적 작업(push/force/delete) 전 확인 요청은 **필수**인데 Pattern 2(`할까요/원하시면`)가 무조건 block.

## 원인

`enforce-execution.sh` L51 Pattern 1은 `하겠습니다` 어미만 검사. 조건절(`~실 때`, `~시면`, `~요청 시`)이나 부정(`~하지 않겠`)이 앞에 붙어도 무차별 매칭.
Pattern 2도 context 없이 `할까요/원하시면` 단독 매칭. CLAUDE.md 파괴적 작업 확인 원칙과 충돌.

## 해결 (2026-04-23 적용)

`enforce-execution.sh` 예외 4종 추가:

| 예외 | 패턴 | 동작 |
|------|------|------|
| 조건부 미래 | `있으실 때\|주시면\|지시.*시\|요청.*시\|필요.*시\|명시.*후\|하시면.*(진행\|반영\|적용)` | Pattern 1 검사 전 exit 0 |
| 부정 선언 | `안 하겠\|하지 않겠\|않겠습니다\|미실행\|실행하지 않\|진행하지 않` | Pattern 1 검사 전 exit 0 |
| 세션 종료 | `마무리\|세션 종료\|커밋 완료\|작업 완료\|배포 완료\|전부 완료\|이번 세션.*성과\|최종 상태` | Pattern 1 검사 전 exit 0 |
| 위험 확인 | Pattern 2 검사 시 `push\|force\|reset\|rebase\|drop\|delete\|삭제\|복구\|롤백\|배포` 공존 시 block 스킵 | CLAUDE.md "Executing actions with care"와 정합 |

## 재발 방지

- Hook 규칙 추가 시 **false positive 시나리오 최소 3개 사전 시뮬레이션** 필수.
- Ghost Mode와 "Executing actions with care"는 **서로 배타 아님** — 파괴적 작업은 확인이 규칙. Pattern 2에 위험 컨텍스트 예외 반드시 포함.
- Hook 예외 추가 시 함수 위치: **패턴 매칭 직전**에 `[ "$HAS_X" -gt 0 ] && exit 0` 형태로 조기 종료 (block 카운터 증가 방지).
