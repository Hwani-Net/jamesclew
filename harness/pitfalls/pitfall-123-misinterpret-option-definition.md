---
slug: pitfall-123-misinterpret-option-definition
title: "옵션 정의를 자체 해석으로 사용자 의도와 어긋나게 적용"
date: 2026-05-10
tags: [pitfall, autonomy-overreach, option-interpretation]
---

# 증상
사용자가 "1로 진행해"라고 명시 결정한 후, 에이전트가 옵션 ①의 정의에 포함된 두 항목(`autoCycleEnabled: false` + 수동 매핑 lock)을 모두 적용. 그러나 사용자의 진짜 의도는 "모델 강제 변경 차단"이었고 자동 사이클은 유지되어야 함. autoCycleEnabled를 false로 바꾼 것은 24시간 자동 운영 중지 = 사용자 의도와 정반대.

# 원인
옵션 ①을 사용자에게 제시할 때 에이전트가 두 항목을 묶어 정의했지만, 사용자가 "1로 진행해"라고 짧게 답한 것을 두 항목 모두 동의로 해석. 사용자의 진짜 목적("모델 변경만 막기")을 재확인 안 함.

# 해결
1. 즉시 autoCycleEnabled: true 복구
2. agent_models.json read-only는 유지 (이게 사용자 의도)

# 재발 방지
**옵션 정의 시 단일 목적 1개만**:
- 잘못: "옵션 ① autoCycleEnabled: false + 매핑 lock"
- 올바름: "옵션 ① 매핑 lock (autoCycleEnabled는 그대로 유지)"
- 또는 둘이 묶여야 한다면 사용자에게 의도 재확인: "두 효과 모두 원하시나요?"

**사용자 명시 결정의 진짜 목적 추출**:
- 사용자: "모델 자꾸 변경되는 거 막아라"
- 진짜 목적 = 모델 변경 차단
- 자동 사이클 = 진짜 목적과 무관 → 건드리면 안 됨

# 자체 검증
- 본 사례 (2026-05-10 02:11) 사용자 직접 지적
- PITFALL-121, 122에 이은 3번째 자율성 경계 위반
