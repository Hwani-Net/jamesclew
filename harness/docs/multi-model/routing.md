# 메인 모델과 외부 모델 라우팅 전략

> Explanation | 대상: JamesClaw 하네스 운영자 | 최종 업데이트: 2026-04-18

---

## 1. 5H/7D 제약과 비용 모델

Claude Code는 두 가지 사용량 제약을 가집니다.

| 제약 | 범위 | 초과 시 |
|------|------|---------|
| 5H 롤링 윈도우 | Opus + Sonnet 공통 | 일시적 rate limit |
| 7D 주간 풀 | Opus / Sonnet **별도** | 주간 한도 소진 |

**외부 모델(Codex CLI, GPT-4.1, Gemma 4 로컬)은 5H와 7D 양쪽 모두 0 소비합니다.** 이것이 라우팅 전략의 핵심입니다. 검수·리뷰·반복 작업을 외부 모델로 위임할수록 Opus 7D 풀이 보존되어 설계·판단에 집중할 수 있습니다.

---

## 2. 실행 모델 풀

| 모델 | 호출 방법 | 강점 | 비용 |
|------|----------|------|------|
| Sonnet 서브에이전트 | `Agent(model: "sonnet")` | 풀 도구 접근, 파일 편집 | 5H 소비 (느림), Sonnet 7D |
| Codex CLI | `bash harness/scripts/codex-rotate.sh "프롬프트"` | 독립적 코드 관점, 6계정 로테이션 | 5H 0, 7D 0 |
| GPT-4.1 (copilot-api) | `curl -s --max-time 30 http://localhost:4141/v1/chat/completions` | 콘텐츠 톤, AI냄새 감지 | 5H 0, 7D 0 |
| Gemma 4 로컬 | Ollama API `localhost:11434` | 무제한, 오프라인 | 0 |
| GLM-5.1 클라우드 | `ollama run glm-5.1:cloud` | 무료, 고성능 | 수동 호출만 (cloud 과금 리스크) |

GPT-4.1 호출 전 copilot-api 서버가 실행 중이어야 합니다: `copilot-api start --port 4141`

---

## 3. 작업별 모델 라우팅 가이드

| 작업 유형 | 1순위 모델 | 교차 검증 |
|-----------|-----------|-----------|
| 코드 작성/수정 | Sonnet 서브에이전트 | Codex 리뷰 |
| 코드 리뷰 | Codex + GPT-4.1 **병렬** | 의견 불일치 시 Opus 최종 판단 |
| 콘텐츠(블로그) 리뷰 | GPT-4.1 | Codex 보조 |
| AI냄새 검사 | GPT-4.1 | — |
| 웹 리서치 | Sonnet(researcher) | — |
| 탐색/파일 검색 | Sonnet(Explore) | — |
| 배포/빌드 | Sonnet(general-purpose) | — |
| 설계 평가 | Codex + GPT-4.1 | 다수결 |
| 벌크/반복 작업 | Gemma 4 로컬 | — |
| Vision 분석 (스크린샷/이미지) | **Opus 4.6 직접 Read** | Sonnet Vision 금지 |

이 표는 강제 규칙이 아닌 가이드입니다. 잘못된 선택은 PITFALLS에 기록하여 진화시킵니다.

---

## 4. Vision 라우팅 규칙 (중요)

Sonnet의 Vision 정확도는 Opus 대비 20~30% 낮습니다 (P-055). **이미지 분석은 반드시 Opus가 직접 수행해야 합니다.**

**Vision이 필요한 케이스**:
- `/design-review` — Stitch 스크린샷과 라이브 페이지 pixel 비교
- `/qa` — UI 버그 스크린샷 분석
- 블로그 이미지-제품 매칭 확인
- Computer Use 엘리먼트 식별 시 좌표 추정

**Sonnet teammate에서 Vision이 필요한 경우 처리 절차**:

```
1. Sonnet teammate가 스크린샷을 /tmp/screenshot.png에 저장
2. Opus 메인 세션에 SendMessage("Vision 분석 요청: path=/tmp/screenshot.png")
3. Opus가 Read("/tmp/screenshot.png")로 직접 이미지 분석
4. 결과를 Sonnet에 반환
```

**Computer Use / Browser 자동화 Vision 이중 패스**:

```
1차 (저비용): ARIA snapshot (mode: "snapshot") 또는 annotated 모드로 ref ID 확보
    -> 텍스트 기반 정확 매칭, 좌표 추정 불필요

2차 (1차 실패 시): mode: "screenshot" 저장
    -> Opus Read(path)로 Vision 분석
    -> 엘리먼트 좌표·상태 명시적 식별
    -> 재클릭
```

---

## 5. 서브에이전트 vs Agent Teams

혼동하기 쉬운 두 패턴의 차이입니다.

| 구분 | 도구 | 특징 | 선택 기준 |
|------|------|------|----------|
| 서브에이전트 | `Agent(model: "sonnet")` | 1회성 위임, 결과만 반환 | 독립 작업 (코딩, 탐색, 배포) |
| Agent Teams | `TeamCreate` + `SendMessage` + `TaskList` | 지속 팀, teammate 간 직접 DM 가능 | 검수자가 작업자에게 직접 수정 지시해야 하는 구조 |

"Agent"라고만 쓰면 서브에이전트를 의미합니다. Teams는 반드시 "Agent Teams"로 표기합니다.

**HydraTeams 프록시**: Agent Teams의 teammate를 GPT-4.1 등 외부 모델로 라우팅합니다.

```bash
# HydraTeams 시작 (port 3456)
node harness/tools/HydraTeams/dist/index.js \
  --model gpt-4o-mini --provider openai --port 3456 --passthrough lead
```

copilot-api(`localhost:4141`)는 단일 API 호출용, HydraTeams(`localhost:3456`)는 Agent Teams teammate 전용입니다. 혼용하지 마십시오.

---

## 6. Advisor Loop (Opus ↔ 외부 모델 반복 대화)

```
1. 라우팅     Opus가 작업 유형 판단 → 최적 모델 선택
2. 1차 위임   상세 프롬프트 + 제약조건 → 모델 실행
3. 결과 검증  Opus가 결과 검토. 불충분하면 재호출
4. 교차 검증  품질 중요 작업은 2+ 모델 결과 비교
              불일치 시 Opus가 최종 판단
5. 완료       대표님께 요약 전달
```

외부 모델 프롬프트 작성 시 반드시 포함해야 할 항목:
- 목표 + 맥락 + 제약조건 (모델은 대화 맥락을 모름)
- 파일 경로, 라인 번호 등 구체적 정보
- 판단 분기점 사전 식별
- 결과물 형식 지정 (요약 200자, JSON 등)

---

## 7. GPT 메인 전환 (5H 소진 시)

5H가 소진되면 GPT-4.1을 Claude Code 메인 모델로 전환할 수 있습니다.

```bash
# 1. copilot-api 서버 시작
copilot-api start --port 4141 &

# 2. GPT-4.1을 메인으로 새 세션 시작
ANTHROPIC_BASE_URL=http://localhost:4141 claude

# 3. Opus 어드바이저는 반드시 별도 Claude Code 세션으로 유지
```

**주의**: GPT-4.1 프록시 세션에서 `/model opus` 선택 시 에러가 발생합니다. Opus 어드바이저는 별도 터미널 세션에서만 운영합니다. GPT-4.1은 오케스트레이터에 부적합(Opus 대비 60-65% 수준)하므로 단순 반복·벌크 작업에만 사용합니다.

---

## 8. 80%+ 비상 모드

5H 사용량 80% 초과 감지 시 다음 규칙이 자동 적용됩니다.

1. Opus 응답을 **최대 2문장**으로 제한
2. 모든 도구 호출을 Sonnet 서브에이전트로 위임 (Opus 직접 호출 금지)
3. 대표님께 "5H 80%+, Sonnet 위임 모드" 고지
4. 리밋 해제 후 `/model opus`로 복귀

5H 현재 수치는 `bash ~/.claude/hooks/telegram-notify.sh heartbeat`로 확인합니다. 추측 금지.

---

## 9. v2.1.113~114 관련 안정화 (2026-04-18 반영)

- **서브에이전트 stall 자동 실패 (v2.1.113)**: Agent 호출 후 10분간 stream 없으면 clear error로 자동 실패. 기존엔 silent hang이었으나 이제 Opus가 명시적으로 감지 가능. 하네스 R14 watchdog과 중복 없이 상호 보완.
- **네이티브 바이너리 spawn (v2.1.113)**: CLI가 번들 JS 대신 플랫폼별 네이티브 바이너리를 실행. 시작 속도 개선. 사용자 체감 동일, 라우팅 로직 영향 없음.
- **Agent Teams permission dialog crash fix (v2.1.114)**: teammate가 도구 권한 요청 시 crash 해결. HydraTeams 프록시 경유 teammate 운영 안정화.
- **`find -exec`/`-delete` 자동 승인 제외 (v2.1.113)**: `Bash(find:*)` allow rule이 있어도 find의 실행·삭제 플래그는 승인 프롬프트. 파괴적 명령 방어 레이어 추가.

---

## 관련 파일

- CLAUDE.md Multi-Model Orchestration 섹션
- `D:/jamesclew/harness/tools/HydraTeams/`
- `D:/jamesclew/harness/scripts/codex-rotate.sh`
- P-055: Sonnet Vision 정확도 격차
- P-029: Ralph Loop + GPT-4.1 copilot-api 연동 패턴
