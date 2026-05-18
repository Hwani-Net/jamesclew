---
title: pitfall-156 — 도구 없는 에이전트가 가짜 URL/날짜/뉴스를 사실인 양 생성
slug: pitfall-156-agent-tool-hallucination-without-web-search
date: 2026-05-17
tier: distilled
tags: [agent, hallucination, researcher, web-search, tool-binding, fake-url, connect-ai-lab, content-safety]
---

## 증상

자율 사이클의 Researcher(또는 비슷한 정보 조사 에이전트)가 외부 웹 검색 도구 없이도 "뉴스 3건 조사 + 표 정리" 같은 작업을 받으면 **실재하지 않는 URL과 날짜·수치를 사실인 양 출력**한다.

실측 사례 (Connect AI Lab `_company/sessions/2026-05-17T01-42/researcher.md` 등 20세션 연속):
- `yna.co.kr/view/AKR202605170800000005` — 연합뉴스 형식이지만 실재 URL 아님
- `etnews.com/view.html?newsid=226582` — 전자신문 형식이지만 실재 URL 아님
- `tool_code` 또는 Python 블록 + "실행 결과: ..." 형태로 코드 실행한 척 출력

이걸 CEO가 보면 "SESSION COMPLETE"로 라벨해 publishing_jobs enqueue 후보로 분류한다. 발행 시스템이 깨어나는 순간 라이브 사이트에 가짜 뉴스가 게재될 수 있다.

## 원인

1. **에이전트 `tools.md`의 도구가 모두 "_(예정)_" 상태**인데도 `brief.md`에서 "뉴스 조사" 작업이 분배됨. extension 자체가 web_search 구현체를 안 가지고 있음.
2. **에이전트 `prompt.md`에 hallucination 차단 룰이 없음**. 빈 stub("자유롭게 적으세요" 안내문만) 상태.
3. 작은 로컬 모델(gemma3:12b, llama3.2:3b)은 학습 데이터에서 본 URL 패턴을 그대로 재조합. "현실에 없는 URL을 만들지 말라"는 메타 자제력 약함.
4. CEO 검증 게이트가 없으면 가짜 출력이 "완료"로 통과.

## 해결

**2층 방어 (도구 자체 추가는 별개 작업)**:

1. **에이전트 `prompt.md` 강화** — "도구 없으면 URL/날짜/수치 출력 금지, 거부 또는 `[학습 데이터]` 라벨" 룰을 시스템 프롬프트에 주입. 예시 형식 2개(거부 / 학습 데이터 디스클레이머) 제공.

2. **CEO `prompt.md`에 검증 게이트 G1-G4** — 도구 실행 0건 세션을 `[INTERNAL_ONLY]`로 분류해 publishing_jobs enqueue 대상에서 자동 제외. URL 검증 + 반복 작업 감지도 함께.

3. **publisher.js DRY_RUN 토글** — 위 보강 효과 검증 전까지 라이브 차단 (`.env`에 `DRY_RUN=true`).

도구 자체(Tavily 등) 바인딩은 별개 작업으로 진행 — 보통 extension 소스 패치 또는 wrapper에 검색 어댑터 추가 필요.

## 재발 방지

1. 새 에이전트 도입 시 **tools.md를 가장 먼저 확인**. 도구 매니페스트가 "_(예정)_" 또는 비어있으면 그 에이전트에게 외부 정보 조사 작업을 분배하지 말 것.
2. 자율 사이클 첫 N회 후 sessions/ 산출물의 URL을 무작위 샘플링해 `curl -I` 200 응답 검증. 가짜 URL 비율이 0이 아니면 위 2층 방어 즉시 적용.
3. CEO 보고서에 `SESSION COMPLETE` 라벨만 보지 말고 **에이전트별 `🔧 도구 실행: ...` 줄을 확인**. "_(없음 — LLM 추론만)_" 이 다수면 그 cycle은 발행 후보가 아님.
4. 작은 로컬 모델(7B~13B)일수록 hallucination 자제력 약함. 발행 직결 에이전트(writer, researcher)는 모델 업그레이드 또는 strict prompt 보강 우선.

## 관련

- [[pitfall-157-publisher-collection-mismatch]]
- [[pitfall-158-ollama-proxy-duration-zero]]
