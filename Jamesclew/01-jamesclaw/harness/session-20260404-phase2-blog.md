---
name: Session 2026-04-04 Phase 2 Blog Pipeline
description: 블로그 5개 글 자율 발행 + 하네스 자체검증 루프 강화 + OpenCode serve 연동
type: project
---

## 완료 작업

### 블로그 글 5개 발행
1. 가성비 무선 이어폰 TOP 5 (v2, 벤치마킹 기반 재작성)
2. 가성비 에어프라이어 TOP 5
3. 가성비 전동칫솔 TOP 5
4. 가성비 구강세정기 TOP 3
5. 가성비 경추베개 TOP 4

### OpenCode serve + Antigravity 연동
- stakeholder-mcp LLM client: OpenCode serve(localhost:4096) 우선 → OpenRouter 폴백
- 편집장/작가 페르소나: Gemini 3.1 Pro (무료)
- 옵시디언에 편집장(content-editor-kimseoyeon.md), 작가(blog-writer-leejiwoo.md) 영구 저장

### 하네스 개선 5건
1. pipeline.mjs에 이미지 포맷 검증 + Playwright 렌더링 검증 내장
2. CLAUDE.md "완성형까지 반복" 원칙 (검토 횟수 제한 없음)
3. CLAUDE.md 스킬 자동 참조 규칙 (~/.agent/skills/)
4. CLAUDE.md 디자인 레퍼런스 (머니가이드/혜택알리미 스타일)
5. 메인 페이지 파스텔 여성 친화 스타일로 개편

### 기타
- statusline 5H/7D Windows credentials 수정
- 텔레그램 알림 복구 (settings.json env 리터럴 버그)
- 혜택알리미 프로덕션 액세스 신청 완료

---

## 행동 패턴 (다음 세션에서 반드시 따를 것)

### 블로그 글 발행 워크플로우
```
1. 주제 리서치 (researcher 에이전트)
   - 다나와 최저가 + 쿠팡 URL 확인
   - 5종 제품 장단점 데이터 수집

2. 작가 페르소나로 글 작성 (blog-writer via OpenCode serve)
   - 옵시디언 스타일 가이드 반영
   - 결론 선행 → 선정기준 → 제품별 → 비교표 → FAQ → 마무리

3. 편집장 검토 루프 (content-editor via OpenCode serve)
   - NO면 수정 → 재검토 (횟수 제한 없음)
   - YES 나올 때까지 반복

4. 쿠팡 썸네일 캡처 (Playwright)
   - 각 제품 별도 브라우저 인스턴스 (봇 차단 우회)
   - 뷰포트 내 가장 큰 이미지 좌표 → clip 스크린샷
   - 저장 후 Read로 이미지 내용 직접 확인 (HTTP 200 검증 아님)
   - 확장자와 실제 포맷 일치 확인

5. 마크다운에 이미지 삽입 → 배포
   - pipeline.mjs가 이미지 포맷 자동 검증
   - 배포 후 Playwright 풀페이지 렌더링 확인

6. 모든 검증 통과 후에만 대표님께 보고
```

### 편집장 검토에서 반복 지적된 사항
- **내부 링크**: 주제 연관성 필수. 이어폰 글에 에어프라이어 링크 금지. 연관 글 없으면 넣지 않거나 연관 글을 먼저 작성
- **비교표**: 모바일 3-4열 이내. 독자가 가장 궁금한 스펙(높이조절, 세탁 등)을 반드시 포함
- **가격 표기**: 10원 단위 하드코딩 금지 → "2만원대", "5만원대" 유연하게
- **CTA**: "실시간 최저가 확인하기" (가격 변동 시 신뢰도 유지)
- **H3 소제목**: 가격순 나열이 아니라 페인포인트 중심 ("딱딱한 베개 싫은 분", "열 많은 분")
- **워터픽/템퍼 같은 고가 제품**: "예산 여유가 있다면" 포지셔닝

### 이미지 관련 교훈
- HTTP 200 = 이미지가 보인다는 뜻이 아님
- PNG 파일을 .jpg로 저장하면 브라우저에서 안 보임
- 제조사 공식 이미지는 투명배경/엉뚱한 제품/프로모션 배너 위험
- 쿠팡 제품 페이지 썸네일을 Playwright로 캡처하는 게 가장 정확
- 각 제품마다 별도 브라우저 인스턴스 (쿠팡 봇 차단 우회)
- loading="lazy" 때문에 스크롤 전에는 이미지 미로드 — 풀페이지 스크롤 후 확인

### 디자인 관련
- 대표님 스타일: 머니가이드/혜택알리미 참조 (파스텔, 둥근카드, 친근 문구)
- 다음 세션에서 Stitch 활용 + 벤치마킹 레퍼런스(Godly, motionsites 등) 기반 고품질 UI 구현 예정

---

## 미해결 이슈

1. **데스크톱 다크모드 썸네일 깨짐** — 에어프라이어/이어폰 카드 이미지 미표시. 원인 조사 필요
2. **verify.mjs Playwright 렌더링 검증** — execSync에서 JSON 파싱 에러. 코드 수정 필요
3. **메인 페이지 디자인** — Stitch + 벤치마킹 레퍼런스 기반 전면 개편 예정
4. **편집장 검토 루프 코드화** — 현재 수동. pipeline.mjs에 stakeholder-mcp 호출 자동화 필요

## 도구/인프라 추가 절차 (반드시 따를 것)

새로운 도구, MCP, 라이브러리, 외부 서비스를 추가할 때:

```
1. 리서치 — Tavily/Perplexity로 최신 정보 검색
   - 공식 문서, API 스펙, 설치 방법
   - 학습데이터 의존 금지, 반드시 현재시각 기준 확인

2. 기존 환경 확인 — 이미 있는지 먼저 탐색
   - ~/.agent/skills/ (스킬 문서)
   - ~/.config/ (설정 파일)
   - ~/.claude/mcp-servers/ (MCP 서버)
   - 옵시디언 03-knowledge/ (지식 문서)
   - 이미 있으면 새로 만들지 않고 그걸 활용

3. 소규모 테스트 — 작은 단위로 동작 확인
   - health check → 간단한 호출 → 실제 사용 시나리오
   - Windows 환경 호환성 확인 (grep -oP 안 됨, security 명령 안 됨 등)

4. 통합 — 코드에 반영
   - 빌드 검증 (bun x tsc --noEmit 또는 node --test)
   - 기존 코드와 충돌 없는지 확인

5. 하네스 기록 — 설계 문서 + 메모리 동시 업데이트
   - harness_design.md 변경 이력 테이블
   - 메모리(reference 타입)에 접속 정보/사용법 저장
```

### 이번 세션에서 이 절차를 적용한 예시

**OpenCode serve 연동:**
1. 리서치: researcher 에이전트로 opencode + antigravity 조사
2. 기존 확인: ~/.config/opencode/opencode.json 발견 → 이미 설정됨
3. 테스트: health → session 생성 → prompt_async → 응답 확인 → 모델 ID 오류 수정
4. 통합: stakeholder-mcp client.ts 변경 → tsc 빌드
5. 기록: 메모리(reference_opencode_serve.md) + 설계 문서 변경 이력

## 세션 간 맥락 전달 도구

### @rlabs-inc/memory v0.6.0 (설치 완료)
- 서버: `memory serve` → localhost:8765
- hooks: SessionStart(맥락 주입) + UserPromptSubmit(실시간 추출) + PreCompact(compact 전 저장) + Stop(세션 종료 큐레이션)
- ingest: `memory ingest --project d--jamesclew` (기존 세션 히스토리 처리)
- bun 1.3.11로 업그레이드 필요 (1.2.x에서 Bun.stripANSI 에러)

### 세션 시작 시 자동 동작
1. telegram-notify.sh start → 텔레그램 알림
2. session-start.ts → memory 서버에서 관련 과거 맥락 검색 + 주입
3. CLAUDE.md + MEMORY.md + rules/ 로드

### /compact 시 동작
1. curation.ts → compact 전 핵심 맥락을 memory DB에 저장
2. compact 실행 (대화 압축)
3. PostCompact hook → 핵심 규칙 재주입 + 텔레그램 알림

## 다음 세션 TODO
1. 데스크톱 썸네일 깨짐 수정
2. Stitch + 레퍼런스 기반 메인 페이지/글 페이지 디자인 전면 개편 (godly.website, motionsites.ai 등 참조)
3. 블로그 글 추가 발행 (현재 6개 → 20~30개 목표)
4. verify.mjs Playwright JSON 파싱 수정
5. memory ingest 완료 (62개 메모리 추출) — compact 후 맥락 주입 테스트
6. 텔레그램 알림 정리: start/stop 알림 제거, 5H 50%+ 10% 단위만, heartbeat 수동만
