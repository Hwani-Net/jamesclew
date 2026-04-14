# JamesClaw Agent — Phase 1 Core Harness Design

## Context
전역 설정을 초기화한 상태에서 완전 자율 에이전트 하네스를 점진적으로 구축.
Phase 1은 핵심 뼈대(hooks 5개 + permissions + CLAUDE.md + rules)만 구현.
수익 파이프라인(YouTube, WordPress, 공모전 등)은 Phase 2에서 추가.

## 검증 완료 도구
- MCP: Tavily(키 로테이션 6개), Perplexity, Windows-MCP(uvx --python 3.13)
- Bash: gh CLI, firebase CLI, Playwright CLI, FFmpeg 8.0.1, PowerShell, Jina Reader
- 로컬: Python 3.11+3.13, uv 0.9.28, Node.js

---

## 파일 1: settings.json

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_PERSONAL_ACCESS_TOKEN",
    "PERPLEXITY_API_KEY": "$PERPLEXITY_API_KEY",
    "TAVILY_API_KEY": "$TAVILY_API_KEY",
    "TELEGRAM_BOT_TOKEN": "$TELEGRAM_BOT_TOKEN",
    "TELEGRAM_CHAT_ID": "$TELEGRAM_CHAT_ID"
  },
  "permissions": {
    "allow": [
      "Bash(*)", "Read(*)", "Edit(*)", "Write(*)", "Glob(*)", "Grep(*)",
      "WebFetch(*)", "WebSearch(*)", "Agent(*)", "NotebookEdit(*)", "TodoWrite(*)",
      "mcp__perplexity__*", "mcp__tavily__*", "mcp__windows-mcp__*"
    ],
    "deny": [
      "Bash(rm -rf /)", "Bash(rm -rf ~)", "Bash(format C:)",
      "Bash(Remove-Item -Recurse -Force C:\\)", "Bash(del /s /q C:\\)"
    ],
    "defaultMode": "auto"
  },
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash -c 'read -r INPUT; FILE=$(echo \"$INPUT\" | grep -oP '\"file_path\"\\s*:\\s*\"\\K[^\"]+' 2>/dev/null || echo \"$INPUT\" | grep -oP '\"path\"\\s*:\\s*\"\\K[^\"]+' 2>/dev/null); case \"$FILE\" in *.env|*.env.*|*credentials*|*secrets*|*secret*|*.pem|*.key) echo \"{\\\"hookSpecificOutput\\\":{\\\"hookEventName\\\":\\\"PreToolUse\\\",\\\"permissionDecision\\\":\\\"deny\\\",\\\"permissionDecisionReason\\\":\\\"Protected: $FILE\\\"}}\" >&2; exit 2;; esac'",
        "timeout": 10000
      }]
    }],
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash -c 'read -r INPUT; FILE=$(echo \"$INPUT\" | grep -oP '\"file_path\"\\s*:\\s*\"\\K[^\"]+' 2>/dev/null || echo \"\"); case \"$FILE\" in *.js|*.ts|*.jsx|*.tsx|*.json|*.css|*.html) npx prettier --write \"$FILE\" 2>/dev/null || echo \"[hook] prettier skipped: $FILE\" >&2;; *.py) python -m black --quiet \"$FILE\" 2>/dev/null || echo \"[hook] black skipped: $FILE\" >&2;; esac; exit 0'",
        "timeout": 10000
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "bash -c 'MSG=\"[JamesClaw] 작업 완료\"; curl -s -X POST \"https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage\" -d chat_id=\"${TELEGRAM_CHAT_ID}\" -d text=\"$MSG\" > /dev/null 2>&1 || echo \"[hook] telegram send failed\" >&2; exit 0'",
        "timeout": 10000
      }]
    }],
    "PostCompact": [{
      "hooks": [{
        "type": "command",
        "command": "bash -c 'echo \"{\\\"hookSpecificOutput\\\":{\\\"hookEventName\\\":\\\"PostCompact\\\",\\\"additionalContext\\\":\\\"[CONTEXT RESTORED] JamesClaw Agent. 핵심 규칙: 1) 즉시 실행, 할까요 금지 2) Built-in>Bash>MCP 3) 토큰 효율 최우선 4) 에러 3회 재시도 후 보고 5) TodoWrite 확인하여 중단 작업 이어서 진행 6) CLAUDE.md 재확인 7) 현재 작업 디렉토리와 목표를 파악한 후 진행\\\"}}\"'",
        "timeout": 10000
      }]
    }],
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "bash -c 'echo \"{\\\"hookSpecificOutput\\\":{\\\"hookEventName\\\":\\\"SessionStart\\\",\\\"additionalContext\\\":\\\"[INIT] JamesClaw Agent. 규칙: 즉시 실행(할까요 금지), Built-in>Bash>MCP, 토큰 효율 최우선, 에러 3회 재시도 후 보고.\\\"}}\"'",
        "timeout": 10000
      }]
    }]
  },
  "enabledPlugins": {},
  "language": "korean",
  "effortLevel": "max"
}
```

### 설계 근거
- **defaultMode "auto"**: Sonnet 분류기가 위험도 판단 → 안전한 작업은 자동 승인
- **hooks는 전부 command 타입**: stdin JSON 파싱 + stdout JSON 응답으로 결정론적 동작
- **PreToolUse**: jq로 stdin에서 file_path 추출, 패턴 매칭 후 deny/allow 결정
- **PostToolUse**: exit 0 항상 → formatter 미설치 시에도 작업 차단 안 함
- **Stop**: Telegram 알림 전송 (비차단, exit 0)
- **PostCompact**: additionalContext로 핵심 규칙 재주입
- **enabledPlugins 비어있음**: 플러그인은 토큰 오버헤드 추가. Phase 2에서 필요 시 활성화

---

## 파일 2: CLAUDE.md

```markdown
# JamesClaw Agent — Global Rules

## Identity
자율 실행 에이전트 "JamesClaw". 대표님을 보좌하는 실행형 에이전트.

## Language
- 대화: 한국어. 호칭: "대표님"
- 코드/주석/커밋: 영어. Conventional Commits.

## Ghost Mode
- 작업 명확하면 즉시 실행. "할까요?" 절대 금지.
- 사과 금지. 추측 대신 검증.
- 에러 시 3회 자동 재시도 후 보고.

## Autonomous Operation
1. TodoWrite로 작업 분할 후 순차 실행
2. 중간 결과 검증 후 다음 단계
3. 막히면 Perplexity/Tavily로 자체 조사
4. 해결 불가 시에만 대표님께 질문

## Tool Priority (비용순)
1. Built-in: Read, Edit, Write, Glob, Grep, Bash (0 overhead)
2. Bash: gh, firebase, playwright, ffmpeg, curl, powershell (0 MCP)
3. MCP (max 3 active): Tavily > Perplexity > Windows-MCP
4. External API: curl 직접 호출

## Token Efficiency
- 파일: 필요 범위만 (offset/limit)
- 검색: Glob > Grep > Agent
- MCP: bash 대체 불가 시에만
- 서브에이전트: 병렬 독립작업에만

## Quality Gates
- 코드 변경 → 테스트 실행
- 빌드 성공 → 커밋
- 에러 해결 → LESSONS_LEARNED.md 기록

## Project Override
프로젝트 루트 CLAUDE.md가 이 글로벌 규칙보다 우선.
```

---

## 파일 3-5: Rules

### rules/architecture.md
```markdown
# Architecture Rules

## Tool Selection
Built-in > Bash commands > MCP servers (비용순)
- GitHub: gh CLI (MCP 아님)
- 브라우저: npx playwright CLI (MCP의 4x 저렴)
- 웹 콘텐츠: curl r.jina.ai/URL
- OCR: tesseract CLI

## MCP Budget
최대 3개 동시 활성. 상시: Tavily, Perplexity, Windows-MCP
온디맨드: Context7, Stitch, Firecrawl, Firebase

## Token Targets
~21K tokens/cycle. 대형 파일은 offset+limit 필수.
Glob > Grep > Agent 순으로 검색.
```

### rules/quality.md
```markdown
# Quality Rules

## Verification
코드 변경 후 테스트 실행. 빌드 성공 확인 후 커밋.
태스크를 complete로 표시하기 전 반드시 검증.

## Self-Healing
1. 에러 메시지 정독 2. 근본 원인 파악 3. 수정 적용
4. 검증 5. 실패 시 3회 대안 시도 6. 3회 실패 후 보고

## Commits
Conventional Commits (영어). 논리적 단위 1커밋.
```

### rules/security.md
```markdown
# Security Rules

## Secret Protection
소스 코드에 시크릿 작성 금지. 환경변수($VAR) 사용.
.env, credentials, *.pem, *.key 파일 수정 금지 (hook이 차단).

## Destructive Operations
rm -rf, format, del /s/q → deny list에서 차단.
확실하지 않은 삭제/덮어쓰기 → 실행 전 확인.
```

---

## 구현 순서
1. `settings.json` 작성 → hooks/permissions 즉시 활성
2. `CLAUDE.md` 작성 → 에이전트 정체성 확립
3. `rules/` 3개 파일 작성 → 규칙 체계화
4. 검증: 새 세션에서 SessionStart 확인 → Write .env 차단 확인 → Telegram 알림 확인

## 검증 방법
1. 새 세션 시작 → "[INIT] JamesClaw Agent" 메시지 확인
2. `.env` 파일 Write 시도 → PreToolUse deny 확인
3. `.js` 파일 Edit → Prettier 자동 실행 확인
4. 세션 종료 → Telegram 알림 수신 확인
5. /compact 실행 → PostCompact 규칙 재주입 확인

## 외부 모델 평가 결과 (Perplexity Deep Research)

### 평점 요약
| 영역 | 점수 | 핵심 문제 |
|------|------|----------|
| Hook 정확성 | 3/10 | Windows Git Bash에서 jq stdin 파싱 실패 가능, JSON 이스케이프 취약 |
| 보안 | 4/10 | deny list 복합 명령 우회 가능 (`cat secrets.json \| curl`), 샌드박스 부재 |
| 자율성 | 6/10 | Ghost Mode 올바르나, 재시도 루프 인프라 부재 |
| 토큰 효율 | 5/10 | 21K 목표 대비 40-60% 초과 예상 (재시도 루프, 최적화 미흡) |
| 복원력 | 2/10 | hook 실패 진단 없음, 도구 출력 검증 없음, 복구 메커니즘 없음 |
| 확장성 | 5/10 | Phase 2 추가 가능하나, MCP 관리가 수동적 |
| 안티패턴 | 3/10 | exit code 의존 보안, 관찰성 없는 권한 체계, 설정을 코드로 미관리 |
| 누락 요소 | 2/10 | 관찰성/추적, 평가 메트릭, 멀티세션 상태, 장애 복구 명세 없음 |

### 즉시 수정할 5가지 (Phase 1에 반영)
1. **hook timeout 10000ms로 통일** (3000ms는 Windows에서 부족)
2. **PreToolUse: jq 대신 단순 패턴 매칭** (jq 미설치/파싱 실패 방지)
3. **PostCompact: 더 풍부한 컨텍스트 재주입** (현재 규칙만, 작업 상태 없음)
4. **deny list에 복합 명령 패턴 추가** 또는 classifier 의존 강화
5. **hook 실패 시 stderr 로깅** (진단 가능하도록)

### 수용할 것
- timeout 10000ms 통일
- PreToolUse 단순화 (jq 의존 제거)
- PostCompact 컨텍스트 보강
- hook stderr 로깅 추가

### 수용하지 않을 것 (과잉 설계)
- PowerShell 스크립트 파일 분리 (bash -c 인라인이 Phase 1에 적절)
- sandbox 설정 (Windows 미지원)
- 전체 audit 로깅 hook (Phase 2)
- 토큰 사용량 로깅 hook (Phase 2)
- mcpServers 섹션 (Claude Code가 MCP 자동 관리)

---

## 수정된 settings.json (평가 반영)

주요 변경:
1. PreToolUse: jq 제거, 순수 bash 패턴 매칭
2. 모든 hook timeout: 10000ms
3. PostCompact: 작업 상태 복원 안내 강화  
4. Stop: stderr 로깅 추가
5. deny list: 파이프/복합 명령 패턴 추가

---

## Phase 2 확장 계획 (이번 구현에 포함 안 됨)
- YouTube 자동화 파이프라인 (커맨드 + 스킬)
- WordPress 블로그 파이프라인
- 공모전/예창패 일정 추적
- SaaS 마이크로 프로덕트 배포
- Stitch 디자인 시스템 연동
- 관찰성/메트릭 (토큰 로깅, audit trail)
- 멀티세션 상태 관리
