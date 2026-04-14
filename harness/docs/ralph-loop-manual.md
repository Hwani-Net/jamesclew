# Ralph Loop Plugin — JamesClaw 운영 매뉴얼

## 개요

Ralph Loop은 **Stop hook 기반 자율 반복 루프** 플러그인이다. `/ralph-loop` 커맨드를 한 번 실행하면, Claude가 작업을 마치고 세션 종료를 시도할 때 Stop hook이 이를 가로채 **동일 프롬프트를 재주입**한다. 외부 bash 루프 없이 세션 내부에서 완료 조건 충족까지 자율 반복한다.

Geoffrey Huntley의 "Ralph Wiggum technique" 구현체 — "Ralph is a Bash loop".

## 설치 현황

- 플러그인: `ralph-loop@claude-plugins-official` v1.0.0
- 상태: enabled (user scope)
- Windows 패치 적용: `hooks/hooks.json` → Git Bash 경로로 수정 완료
  - `"C:/Program Files/Git/bin/bash.exe" "${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook.sh"`

## 커맨드 레퍼런스

### /ralph-loop

```
/ralph-loop "<프롬프트>" --completion-promise "<완료 텍스트>" --max-iterations <N>
```

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--completion-promise` | 없음 | 루프 종료 트리거 문자열. Claude가 `<promise>TEXT</promise>` 출력 시 종료 |
| `--max-iterations` | 무제한 | 최대 반복 횟수. 안전망으로 **항상 설정 권장** |

**예시:**
```
/ralph-loop "Firebase Functions로 쿠팡파트너스 링크 클릭 추적 API 구현. 
CRUD + 테스트 + 배포 포함.
완료 시 <promise>COMPLETE</promise> 출력." 
--completion-promise "COMPLETE" --max-iterations 20
```

### /cancel-ralph

```
/cancel-ralph
```

진행 중인 루프 즉시 중단. 상태 파일(`.claude/ralph-loop.local.md`) 삭제.

## 동작 원리

```
[/ralph-loop 실행]
    ↓
상태 파일 생성: .claude/ralph-loop.local.md
    ↓
Claude 작업 수행
    ↓
[세션 종료 시도]
    ↓
Stop hook 인터셉트 → 상태 파일 확인
    ↓
완료 promise 검출? → YES → 루프 종료
                  → NO  → 프롬프트 재주입 + iteration++
    ↓
다음 반복 시작 (파일/git 히스토리 누적됨)
```

## pipeline-run과의 차이

| 항목 | /ralph-loop | /pipeline-run |
|------|-------------|---------------|
| 루프 방식 | Stop hook 자동 재주입 | 스크립트 단계별 순차 실행 |
| 개입 필요 | 없음 (완전 자율) | 없음 (자동 파이프라인) |
| 적합한 작업 | 코드 구현 + 테스트 통과 | 콘텐츠 품질 검토 (블로그 등) |
| 완료 조건 | `<promise>` 태그 or max-iterations | 11단계 전체 PASS |
| 외부 모델 교차검수 | 없음 (단일 Claude) | Codex + GPT-4.1 필수 |
| 토큰 소비 | 반복당 전체 컨텍스트 | 단계별 누적 |

**결론**: 코드 자동 구현/수정은 ralph-loop, 블로그 품질 검수는 pipeline-run.

## JamesClaw 하네스 활용 시나리오

### 1. Firebase Functions 자동 구현
```
/ralph-loop "D:/jamesclew/blog 프로젝트에 Analytics API 구현.
요구사항: 클릭 추적, BigQuery 연동, 테스트 커버리지 80%+.
firebase deploy --only functions 성공 후 <promise>DEPLOYED</promise> 출력."
--completion-promise "DEPLOYED" --max-iterations 15
```

### 2. 블로그 SEO 자동 수정
```
/ralph-loop "D:/jamesclew/blog/src/content/ 내 모든 글 SEO 검사.
메타디스크립션 누락, 키워드 밀도 2% 미만, 내부링크 0개 항목 수정.
전체 통과 후 <promise>SEO_DONE</promise> 출력."
--completion-promise "SEO_DONE" --max-iterations 10
```

### 3. 테스트 자동 통과 루프
```
/ralph-loop "npm test 실행. FAIL이 있으면 소스 수정 후 재실행.
모든 테스트 PASS 확인 후 <promise>ALL_GREEN</promise> 출력."
--completion-promise "ALL_GREEN" --max-iterations 25
```

## 프롬프트 설계 원칙 (공식 README 확인 항목 ✅, 영상 실천법 ⚠️)

### 핵심 원칙 (공식 확인 ✅)

1. **완료 조건 명확화** ✅ — 모호한 "잘 만들어" 금지. 검증 가능한 기준 명시
2. **`--max-iterations` 항상 설정** ✅ — 무한 루프 방지. 작업 복잡도 × 1.5배로 설정. completion-promise는 exact match라 단일 조건만 처리 → max-iterations가 1차 안전망
3. **자기 수정 지시(TDD 사이클)** ✅ — "테스트 실패 시 소스 수정 후 재실행. 반복 후 COMPLETE 출력" 패턴
4. **Phase별 분할** ✅ — 대형 작업은 Phase 1→2→3으로 별도 ralph-loop 실행. 공식 "Incremental Goals" 패턴 채택
5. **막힌 경우 탈출 지시** ✅ — "N회 반복 후에도 실패하면 원인 문서화 후 BLOCKED 출력"

### 4파일 분리 전략 (영상 실천법 ⚠️ — 공식 미확인, 대규모 작업 권장)

공식 README는 인라인 프롬프트 예시만 제공하나, 대규모 작업에서 토큰 낭비·집중력 저하 방지를 위한 실전 패턴:

```
project/
├── PROMPT.md        # 목표, 완료 조건, 제약, 작업 규칙 (매 루프 재읽기)
├── specs/           # 기능별 요구사항 문서 (필요 시 참조)
│   ├── auth.md
│   └── api.md
├── todo.md          # AI가 자체 관리하는 실행 계획 (루프 간 누적)
└── AGENTS.md        # 빌드/테스트/구조 가이드 (처음 비워두면 AI가 채움)
```

**PROMPT.md 템플릿:**
```markdown
## 목표
[달성할 최종 상태]

## 완료 조건
- [ ] 조건 1 (검증 가능한 형태)
- [ ] 조건 2
모든 조건 충족 시 출력: COMPLETE

## 제약
- 수정 금지 파일: [목록]
- 사용 금지 라이브러리: [목록]

## 작업 규칙
1. todo.md 읽기 → 다음 태스크 실행 → todo.md 업데이트
2. 테스트 실패 시 소스 수정 후 재실행
3. 막히면 AGENTS.md 참조
```

**적용 기준**: 인라인 프롬프트 300자 초과 or 반복 횟수 10회+ 예상 시 4파일 분리 권장.

## JamesClaw 전용 활용 가이드

### 블로그 생성 (ralph-loop + pipeline-run 조합)

```
# 1단계: ralph-loop으로 초안 대량 생성 (반복 자동화)
/ralph-loop "D:/jamesclew/blog/src/content/에 블로그 글 초안 작성.
키워드 파일: specs/keywords.md 참조. 하루 3편 목표.
각 글: 2000자+, H2/H3 구조, 쿠팡 링크 1개 이상.
specs/keywords.md의 미완료 항목 소진 후 COMPLETE 출력."
--completion-promise "COMPLETE" --max-iterations 15

# 2단계: pipeline-run으로 품질 검수
/pipeline-run  # 생성된 글 전체 SEO·AI냄새·이미지 검수
```

### 코드 구현 (specs/ + AGENTS.md)

```
/ralph-loop "PROMPT.md와 specs/ 폴더를 읽고 Firebase Functions 구현.
AGENTS.md에 빌드/테스트 명령어 기록해 두었음.
npm test 전체 PASS + firebase deploy 성공 후 COMPLETE 출력."
--completion-promise "COMPLETE" --max-iterations 20
```

### Phase 분할 실행 (대규모 프로젝트)

```bash
# Phase 1: 인증
/ralph-loop "Phase 1 ONLY: JWT 인증 구현. tests/auth.spec.ts PASS 후 PHASE1_DONE 출력." \
  --completion-promise "PHASE1_DONE" --max-iterations 10

# Phase 2: API (Phase 1 완료 후)
/ralph-loop "Phase 2 ONLY: 상품 API 구현. Phase 1 코드 건드리지 말 것. PHASE2_DONE 출력." \
  --completion-promise "PHASE2_DONE" --max-iterations 10
```

## 주의사항

### 토큰 소비 예측
- **반복당 소비**: 평균 컨텍스트 크기 × 반복 횟수. 예: 10K 토큰 컨텍스트 × 20회 = 200K 입력 토큰
- **5H 리밋 영향**: ralph-loop도 Sonnet/Opus 세션이므로 5H 소비. 장기 루프(10회+) 전 Sonnet 메인 전환 필수
  - 전환: `/model sonnet` → ralph-loop 시작
  - 완료 후: `/model opus` 복귀
- **compact 리스크**: 긴 루프는 자동 compact 발생 → 컨텍스트 손실 가능. 4파일 분리로 완화 (todo.md에 상태 외부화)

### 사용 금지 상황
- **공유 코드베이스 금지** ⚠️ — 다른 개발자와 같이 쓰는 리포지토리에서 실행 금지. Greenfield 프로젝트 또는 1인 개발 전용. (공식 "Greenfield projects where you can walk away" 근거)
- **인간 판단 필요 작업**: 디자인 결정, UX 방향성 등 → ralph-loop 부적합. 공식 명시
- **불명확한 완료 조건**: "잘 만들어" 수준의 모호한 목표 → 무한 루프 위험

### 기타
- **completion-promise 정확 일치**: 대소문자 포함 exact match. 복수 조건 불가 → max-iterations 안전망 필수
- **Windows 패치 필수**: hooks.json Git Bash 경로 수정 없으면 WSL 오류로 hook 무효화
- **상태 파일 위치**: 프로젝트 루트 `.claude/ralph-loop.local.md` — 세션 격리

## 파일 위치

| 파일 | 경로 |
|------|------|
| 플러그인 | `~/.claude/plugins/cache/claude-plugins-official/ralph-loop/1.0.0/` |
| Stop hook | `…/hooks/stop-hook.sh` |
| hooks.json (Windows 패치됨) | `…/hooks/hooks.json` |
| 상태 파일 (런타임) | `<project>/.claude/ralph-loop.local.md` |

## Plugin Monitors (v2.1.105+)
v2.1.105에서 플러그인 매니페스트에 `monitors` 최상위 키가 추가됨.
세션 시작 또는 스킬 호출 시 백그라운드 모니터가 자동 활성화(auto-arm).
현재 생태계에 사용 예시 없음 — 공식 문서 확인 후 ralph-loop 적용 검토.

---
*작성: 2026-04-12 | 업데이트: 2026-04-14*
*출처: anthropics/claude-code plugins/ralph-wiggum README.md (공식) + 영상 실천법 교차 검증*
*팩트체크: ✅ 공식 확인 | ⚠️ 영상 실천법 (공식 미확인)*
