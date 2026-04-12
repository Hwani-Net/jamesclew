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
| 외부 모델 교차검수 | 없음 (단일 Claude) | Codex + Antigravity 필수 |
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

## 프롬프트 작성 필수 원칙

1. **완료 조건 명확화** — 모호한 "잘 만들어" 금지. 검증 가능한 기준 명시
2. **`--max-iterations` 항상 설정** — 무한 루프 방지. 작업 복잡도 × 1.5배로 설정
3. **자기 수정 지시 포함** — "에러 발생 시 메시지 읽고 수정 후 재시도" 명시
4. **단계별 목표** — 대형 작업은 Phase 1→2→3으로 분리
5. **막힌 경우 탈출 지시** — "15회 반복 후에도 실패하면 원인 문서화 후 BLOCKED 출력"

## 주의사항

- **토큰 소비**: 반복마다 전체 컨텍스트 재전송. 긴 세션은 compact 발생 가능
- **completion-promise 정확 일치**: 대소문자 포함 exact match. 복수 조건 불가 → max-iterations 안전망 필수
- **Windows 패치 필수**: hooks.json Git Bash 경로 수정 없으면 WSL 오류로 hook 무효화
- **상태 파일 위치**: 프로젝트 루트 `.claude/ralph-loop.local.md` — 세션 격리, 다른 세션에서 시작한 루프는 현재 세션에 영향 없음
- **5H 소비 주의**: 반복당 Opus/Sonnet 토큰 소비. 장기 루프는 Sonnet 메인으로 전환 후 실행 권장

## 파일 위치

| 파일 | 경로 |
|------|------|
| 플러그인 | `~/.claude/plugins/cache/claude-plugins-official/ralph-loop/1.0.0/` |
| Stop hook | `…/hooks/stop-hook.sh` |
| hooks.json (Windows 패치됨) | `…/hooks/hooks.json` |
| 상태 파일 (런타임) | `<project>/.claude/ralph-loop.local.md` |

---
*작성: 2026-04-12 | 출처: plugin README + stop-hook.sh 분석*
