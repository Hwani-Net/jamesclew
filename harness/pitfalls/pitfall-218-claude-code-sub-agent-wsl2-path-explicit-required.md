---
title: pitfall-218 — Opus sub-agent 위임 시 OpenClaw 관련 작업은 WSL2 경로 명시 강제
slug: pitfall-218-claude-code-sub-agent-wsl2-path-explicit-required
date: 2026-05-26
type: pitfall
tags:
  - claude-code
  - sub-agent
  - sonnet
  - wsl2
  - openclaw
  - path-explicit
  - delegation-prompt
severity: high
related:
  - pitfall-194-task-completed-without-external-evidence
  - pitfall-207-codex-openclaw-path-anti-pattern
  - pitfall-217-claude-code-askuserquestion-multi-choice-permanent
---

# pitfall-218 — Opus sub-agent 위임 prompt에 WSL2 절대 경로 명시 강제

## 메타

- **발견일**: 2026-05-26 08:30 (KST)
- **영향**: Opus가 위임한 P-213~P-216 5건 영구 인프라화 작업 — 적용 효과 0 (잘못된 파일 수정)
- **재발 빈도**: WSL2/Windows 듀얼 환경에서 OpenClaw 인프라 작업마다 잠재 위험
- **검증 자료**:
  - WSL2 실제 운영 파일: `/home/creator/.openclaw/workspace/AGENTS.md` (38958 bytes, 08:32 수정 시점에 P-218 후속 복구 반영)
  - Windows 미사용 파일: `C:/Users/AIcreator/.openclaw/workspace/AGENTS.md` (12257 bytes, OpenClaw 런타임이 읽지 않음)
  - sub-agent ID: `a30ba9af340d93a58` (Sonnet, 작업 명: "P-213~P-216 5건 영구 인프라화")

## 증상

Opus 메인 세션이 Sonnet sub-agent에 OpenClaw 워크스페이스의 `AGENTS.md` 5건 (P-213/P-214/P-215/P-216) 영구 인프라화 작업을 위임했다.

- Sub-agent는 자율적으로 경로 추측 → Windows fs 경로 (`C:/Users/AIcreator/.openclaw/workspace/AGENTS.md` 또는 `/mnt/c/Users/AIcreator/.openclaw/workspace/AGENTS.md`) 선택
- 5건 모두 Windows 파일에 적용 완료 보고
- 결과: 12257 bytes Windows 파일에 5건 반영. OpenClaw 런타임은 WSL2 측 `/home/creator/.openclaw/workspace/AGENTS.md`만 읽으므로 **실제 영향 0**
- WSL2 측은 P-213~P-216 적용 전 상태 1시간 지속 (08:30 발견까지)

대표님 지적 (2026-05-26 08:30): "sub-agent가 잘못된 경로 수정함. WSL2 측이 source of truth. 위임 prompt에 경로 명시 누락 시 다시 발생."

## 진단 과정

1. **WSL2 측 grep**: P-213/P-214/P-215/P-216 키워드 0건 발견 → 적용 실패 확인
2. **Windows 측 grep**: 4건 모두 발견 → sub-agent가 Windows 파일 수정 확인
3. **OpenClaw 런타임 검증**: gateway/codex/ollama 모든 워커가 WSL2 user unit에서 동작 (CLAUDE.md "WSL2 환경 — gateway는 user unit 단독 운영" 명시) → WSL2 = source of truth
4. **bytes 비교**:
   - WSL2: 38958 bytes (모든 영상 패턴 + 5건 반영 후 크기, 복구 완료 시점 기준)
   - Windows: 12257 bytes (구버전, OpenClaw 미사용)
   - 두 파일 크기 차이 26701 bytes — 동일 source 아님이 명확

## 진짜 메커니즘

Opus가 sub-agent에 위임할 때 prompt에 **OpenClaw 작업의 WSL2 절대 경로**를 명시하지 않았다.

```
[잘못된 위임 prompt 예시]
"workspace/AGENTS.md에 P-213~P-216 5건 추가해줘"
"OpenClaw AGENTS.md에 영구 규칙 적용"
```

이런 모호한 prompt를 받은 Sonnet sub-agent는:
1. CWD를 기준으로 fs 탐색 → Windows fs가 먼저 노출 (Claude Code Windows 네이티브)
2. `C:/Users/AIcreator/.openclaw/workspace/AGENTS.md` 발견 → 이게 OpenClaw 파일이라 추측
3. Windows 경로에 5건 적용 → 작업 완료 보고

Sub-agent는 OpenClaw가 **WSL2에서만 동작**한다는 것을 모른다. CLAUDE.md STICKY DECISIONS는 sub-agent SystemPrompt에 자동 주입되지만, sub-agent가 그 명시를 우회/누락하기 쉽다.

이건 PITFALL-207 (codex가 `~/.openclaw/plugin-skills/...` 안티패턴 경로 추측)의 변형 — **sub-agent도 동일한 추측 오류**를 일으킨다.

## 영상 패턴 외 — 우리 메인 세션 인프라 안전 규칙

본 PITFALL은 영상 패턴(UsT1-E1Txyo)이 아니라 **우리 OpenClaw 운영 인프라의 안전 규칙**이다.

OpenClaw 환경:
- **운영 측 (source of truth)**: WSL2 Ubuntu `/home/creator/.openclaw/...`
- **사용 안 함 (구버전)**: Windows `C:/Users/AIcreator/.openclaw/...`
- gateway/codex worker/ollama worker 모두 WSL2 user unit에서 단독 실행 (PITFALL-197 참조)

Sub-agent 위임 시 이 환경 차이를 명시적으로 알려야 한다.

## 해결 (자율 강제)

Opus sub-agent 위임 prompt 작성 규칙을 영구화한다.

### 규칙 1 — OpenClaw 관련 모든 sub-agent 위임에 WSL2 절대 경로 명시 강제

```
[올바른 위임 prompt 예시]

WSL2 절대 경로 명시:
"workspace/AGENTS.md (WSL2: /home/creator/.openclaw/workspace/AGENTS.md)에 P-213~P-216 5건 추가"

또는 wsl 실행 명시:
"wsl -d Ubuntu -e bash -c '/home/creator/.openclaw/workspace/AGENTS.md 수정'"
```

### 규칙 2 — Windows 경로 (`C:/`, `/mnt/c/`) 사용 금지

OpenClaw 관련 sub-agent 위임 prompt에:
- `C:/Users/AIcreator/.openclaw/...` — 사용 금지
- `/mnt/c/Users/AIcreator/.openclaw/...` — 사용 금지
- WSL2 절대 경로 (`/home/creator/...`) 또는 wsl 명령 wrapping만 허용

### 규칙 3 — Sub-agent prompt 템플릿 정형화

OpenClaw 작업 sub-agent 위임 시 prompt 첫 줄에 다음 환경 명시 헤더 삽입:

```
[환경 컨텍스트]
- OpenClaw 운영: WSL2 Ubuntu (gateway/codex/ollama 모두 WSL2 user unit)
- AGENTS.md 경로: /home/creator/.openclaw/workspace/AGENTS.md (source of truth)
- AGENTS.md 경로 (Claude/Codex): /home/creator/.openclaw/workspace-claude/AGENTS.md, /home/creator/.openclaw/workspace-codex/AGENTS.md
- Windows 경로 (C:/Users/..., /mnt/c/...)는 구버전 — 절대 수정하지 마라
- 파일 수정 시 반드시 `wsl -d Ubuntu -e bash -c "..."` 또는 위 WSL2 절대 경로 사용
```

### 규칙 4 — Sub-agent 자기 검증 강제

Sub-agent 작업 완료 보고 시 다음 검증을 포함하도록 prompt에 명시:

```
[검증 요구]
- 작업 후 WSL2 측 grep으로 적용 확인: `wsl -d Ubuntu -e bash -c "grep -c '<키워드>' /home/creator/.openclaw/workspace/AGENTS.md"`
- bytes 크기 보고: `wsl -d Ubuntu -e bash -c "wc -c /home/creator/.openclaw/workspace/AGENTS.md"`
- Windows 측 파일 수정 여부 0건 확인
```

## 검증

본 PITFALL 발견 시점 (2026-05-26 08:30) 검증 명령:

```bash
# WSL2 측 — 5건 키워드 적용 여부 (적용 전: 0건, 적용 후: 5건)
wsl -d Ubuntu -e bash -c "grep -cE 'P-213|P-214|P-215|P-216' /home/creator/.openclaw/workspace/AGENTS.md"

# Windows 측 — 잘못 수정된 파일 (12257 bytes, OpenClaw 미사용)
wc -c "C:/Users/AIcreator/.openclaw/workspace/AGENTS.md"

# 두 파일 bytes mismatch 확인 (source of truth 분기)
wsl -d Ubuntu -e bash -c "wc -c /home/creator/.openclaw/workspace/AGENTS.md"
```

## 적용 이력

- **08:30 발견**: 대표님 grep으로 WSL2 측 0건 vs Windows 측 5건 mismatch 감지 → sub-agent 잘못 수정 보고
- **08:31 즉시 복구 위임**: Opus가 신규 sub-agent에 WSL2 절대 경로 명시 + wsl 명령 wrapping 강제 prompt로 재위임
- **08:34 완료**: WSL2 측 `/home/creator/.openclaw/workspace/AGENTS.md` 38958 bytes 도달, 5건 모두 grep 확인
- **08:35 P-218 신규 PITFALL 작성 시작** (본 문서)

## 재발 방지

1. **PITFALL-218 본문** — sub-agent 위임 prompt 작성 규칙 (위 4규칙) 영구화
2. **CLAUDE.md STICKY DECISIONS** — P-218 한 줄 추가 (2026-05-26): "Opus가 sub-agent 위임 시 OpenClaw 관련 작업은 반드시 WSL2 절대 경로 (`/home/creator/...`) 또는 `wsl -d Ubuntu -e bash -c "..."` 명시. Windows 경로 사용 시 sub-agent가 추측 오류로 별개 파일 수정 → 실제 OpenClaw 영향 0."
3. **session-start-active-infra.sh hook** — SessionStart additionalContext에 P-218 핵심 규칙 한 줄 추가 (sub-agent SystemPrompt에도 자동 주입되어 다음 세션부터 효력)
4. **Opus 메인 sub-agent prompt 템플릿** — OpenClaw 작업 위임 시 환경 컨텍스트 헤더 강제 삽입 (체크리스트)

## 안티패턴

- "workspace/AGENTS.md 수정해줘" (절대 경로 없음, drive/플랫폼 모호)
- "OpenClaw AGENTS.md에 X 추가" (어느 fs인지 명시 없음)
- "~/.openclaw/workspace/AGENTS.md 수정" (`~`가 Windows에서 다른 곳을 가리킴, PITFALL-207 변형)
- "Edit C:/Users/AIcreator/.openclaw/workspace/AGENTS.md" (Windows 경로 명시 = 잘못된 파일 수정 보장)
- Sub-agent 작업 후 검증 없이 완료 보고 (PITFALL-194 변형 — 외부 증거 없는 완료)
- 위임 후 WSL2 측 grep 검증 누락

## 검증 명령 (재발 모니터링)

```bash
# 매 sub-agent 위임 후 WSL2 source of truth와 Windows 구버전 bytes mismatch 확인
# (정기 차이가 정상 — 두 파일이 동일해지면 잘못된 동기화 또는 잘못된 수정)
wsl -d Ubuntu -e bash -c "wc -c /home/creator/.openclaw/workspace/AGENTS.md"
wc -c "C:/Users/AIcreator/.openclaw/workspace/AGENTS.md"

# 신규 P-NNN 영구 인프라화 작업 시 WSL2 측 적용 검증 강제
wsl -d Ubuntu -e bash -c "grep -cE 'P-NNN' /home/creator/.openclaw/workspace/AGENTS.md"
```

## 관련

- [[pitfall-194-task-completed-without-external-evidence]] — 외부 증거 없는 완료 보고 — 본 PITFALL은 그 변형 (sub-agent가 자기 수정만 보고, WSL2 검증 누락)
- [[pitfall-207-codex-openclaw-path-anti-pattern]] — codex가 OpenClaw 경로 추측 안티패턴 (`~/.openclaw/plugin-skills/...`) — 본 PITFALL은 그 sub-agent 변형
- [[pitfall-217-claude-code-askuserquestion-multi-choice-permanent]] — 같은 영구 인프라화 라운드에서 발견된 메인 세션 UX 규칙
- CLAUDE.md STICKY DECISIONS > 활성 자율 인프라 > 운영 라이브 — OpenClaw WSL2 환경 명시 (PITFALL-197)
