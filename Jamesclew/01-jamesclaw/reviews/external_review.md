---
name: External Review Results
description: Perplexity Deep Research의 하네스 평가 결과와 수용/거부 판단
type: feedback
---

## 평가 점수 (초기 설계 기준)
- Hook 정확성: 3/10, 보안: 4/10, 자율성: 6/10
- 토큰 효율: 5/10, 복원력: 2/10, 확장성: 5/10
- 전체: 4/10 → 수정 후 예상 6-7/10

## 수용한 피드백
- timeout 10000ms 통일 (3000ms는 Windows에서 부족)
- hook 실패 시 stderr 로깅 추가
- PostCompact 컨텍스트 보강

## 거부한 피드백 (과잉 설계)
- PowerShell 스크립트 파일 분리 — bash -c 인라인이 Phase 1에 적절
- sandbox 설정 — Windows에서 미지원
- 전체 audit 로깅 — Phase 2로 이연
- 토큰 사용량 계측 hook — Phase 2로 이연

## 발견된 버그 (수정 완료)
- Git Bash에서 curl로 이모지+한국어 전송 시 UTF-8 깨짐 → Python urllib로 해결
- Usage API 값 변환 오류 (0.75를 740으로 표시) → Python 조건부 변환으로 해결
- Telegram -d flag로 한국어 전송 실패 → JSON body + Content-Type 해결

**Why:** 외부 평가는 과잉 설계를 유도하는 경향이 있음. 실용적 판단으로 필요한 것만 수용.
**How to apply:** 다음 외부 평가 시에도 "Phase 1에 필요한가?"를 기준으로 취사선택.
