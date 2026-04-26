---
name: pitfall-068-user-context-not-checked-before-recommendation
date: 2026-04-25
severity: P1
category: search_before_solve_violation
---

# 사용자 컨텍스트(이미 보유 자원) 미확인 후 일반 안내

## 증상
의원다나와 TWA APK/AAB 빌드 완료 후 "다음 단계" 안내에서:
> "Google Play Console 가입 (개발자 계정 $25 등록 필요)"

라고 일반적인 신규 가입 절차를 안내함. 대표님이 "나는 이미 hwanizero01@gmail.com으로 play console 가입되어 있잖아. 지식 참고 안했어?"라고 지적.

옵시디언 vault `02-projects/BiteLog/PRD.md`에 명백히:
- Closed Beta: Play Store 내부 테스트 트랙 20명
- GA: Play Store 프로덕션 트랙

`02-projects/tool-guides/stitch.md`에:
- `gcloud config set account hwanizero01@gmail.com`
- `gcloud config set project bite-log-app`

→ 이미 Play Console 개발자 등록 완료된 상태. $25 이미 결제됨.

## 원인
1. **Search-Before-Solve 규칙 무시**: 안내 작성 전 옵시디언/gbrain에서 "Play Console", "개발자 계정", "hwanizero01" 등 키워드 검색을 하지 않음
2. **사용자 보유 자원에 대한 무지**: BiteLog 프로젝트가 같은 vault에 존재함을 인지하지 못함
3. **일반론 폴백**: 모르면 일반적인 신규 가입 안내로 대체. "재방문 사용자" 가정 부재
4. **현재 시각 + 사용자 이력 무시**: 대표님은 1년+ Play Store 출시 경험 있는 개발자. 신규 가입자 가이드는 부적절

## 해결
1. 즉시 옵시디언 grep: `hwanizero01|Play Console` → 4개 파일 발견
2. BiteLog PRD에서 Play Store 트랙 4단계 확인 → 이미 가입됨 확정
3. 정확한 안내 재작성: 신규 가입 절차 제거, 기존 계정으로 새 앱 추가 절차만 안내

## 재발 방지

### 새 프로젝트 시작 시 필수 사전 조회 (CLAUDE.md 0단계 보강)
기존 0단계는 "claude-code-manual + 하네스 docs + gbrain pitfall"이지만 **사용자 보유 자원**도 포함:

```bash
# 외부 서비스/도구 추천 전 필수
grep -ri "<서비스명>" $OBSIDIAN_VAULT/02-projects/  # 다른 프로젝트에서 이미 사용 중인지
grep -ri "<서비스명>|<계정명>|<프로젝트명>" $OBSIDIAN_VAULT/01-jamesclaw/memory/
```

### 안내 작성 전 자가질문
- [ ] "대표님은 이미 이 도구/서비스/계정을 보유 중인가?"
- [ ] "다른 프로젝트(BiteLog/AgentLens 등)에서 이미 사용한 인프라인가?"
- [ ] "신규 가입/결제 안내가 필요한가, 아니면 기존 자원 재사용으로 충분한가?"

### 키워드 트리거
다음 단어 등장 시 무조건 옵시디언 grep:
- "가입", "등록", "개발자 계정", "developer account"
- "Play Console", "App Store Connect", "Apple Developer"
- "$25", "$99", "결제", "유료 등록"
- "신규 프로젝트", "새 앱 만들기"

## 관련 규칙
- CLAUDE.md Search-Before-Solve: "막히면 LESSONS_LEARNED, 옵시디언, 이전 세션에서 먼저 검색"
- CLAUDE.md 0단계 (프로젝트 시작 시 필수 사전 조회) — 사용자 보유 자원 항목 보강 필요

## 유사 패턴
- pitfall-063: 사용자에게 리서치 대행 요구 (이번 건과 다름 — 이번은 "이미 있는데 모름")
- premature_conclusion (10회 누적): 검증 없이 결론 내림
- declare_no_execute (4회 누적): 선언 후 미실행

## 증상→해결 3줄 요약
- **증상**: 사용자가 이미 보유한 도구/계정을 모르고 신규 가입 안내
- **원인**: 안내 작성 전 옵시디언/메모리/이전 프로젝트 미검색
- **해결**: 외부 서비스 언급 시 필수 grep + 자가질문 체크리스트
