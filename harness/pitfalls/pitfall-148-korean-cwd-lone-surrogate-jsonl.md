---
slug: pitfall-148-korean-cwd-lone-surrogate-jsonl
title: "한글을 Python으로 출력하는 SessionStart hook이 Windows에서 lone surrogate 생성 → API 400"
symptom: "claude 실행 시 매 메시지마다 API Error 400 invalid high surrogate. /clear 해도 재발. column 위치만 증가."
tags: [encoding, json, api, utf-16, surrogate, korean, jsonl, sessionstart, python, cp949, windows]
date: 2026-05-11
---

## 증상
```
API Error: 400 The request body is not valid JSON: invalid high surrogate in string: line 1 column NNNNN
```
특정 cwd(주로 한글 경로)에서 claude 실행 시 모든 메시지가 400. `/clear`로도 미해결. column 위치는 메시지마다 증가.

세션 JSONL(`~/.claude/projects/{cwd-slug}/*.jsonl`)의 `attachment` entry(`type=hook_success, hookEvent=SessionStart`) `stdout` 필드 안 `additionalContext`에 lone surrogate(`\udcec옄...`) 누적.

## 원인 (재현 검증 완료)

**범인**: SessionStart hook이 `python3 -c "..."`로 한글 텍스트를 stdout으로 출력하는 구조 (예: `distress-queue-loader.sh`)

**연쇄**:
1. Windows + 한국어 locale + `PYTHONUTF8` 미설정 → Python 기본 stdout 인코딩 = **cp949**
2. hook이 `[자율운영-강 ⚠️]` 같은 한글을 Python으로 출력 → bytes가 **cp949 인코딩**으로 출력 (예: `\xec\xfc...`)
3. Claude Code(Node.js)가 hook stdout 바이트를 **UTF-8로 디코딩** 시도 → invalid sequence → `surrogateescape` 방식으로 `\udcec` 같은 lone surrogate로 변환
4. 그 lone surrogate를 JSON으로 escape하여 JSONL에 기록 (`\\udcec\\uc604...`)
5. 이후 turn에서 그 JSONL 내용 전체가 API 요청 body에 포함 → 400 (JSON에 lone surrogate 불허)

이 세션이 안 깨졌다면: 셸 환경에 `PYTHONUTF8=1`이 이미 있어서. Antigravity/VS Code가 spawn하는 새 Claude Code 프로세스에는 없을 수 있음.

## 해결 (검증 완료)

### 영구 (이번 적용)
글로벌 `~/.claude/settings.json`의 `env` 섹션에 추가:
```json
{
  "env": {
    "PYTHONIOENCODING": "utf-8",
    "PYTHONUTF8": "1"
  }
}
```
Claude Code가 hook을 spawn할 때 이 env가 자식 프로세스에 전달 → Python stdout이 UTF-8로 강제됨.

### 손상 JSONL 정리
백업(`.bak`) 생성 후 lone surrogate를 `�`(�)로 치환. 정리 후 `--resume` 가능.

### 검증 방법
한글 cwd에서:
```bash
PYTHONIOENCODING=utf-8 PYTHONUTF8=1 bash ~/.claude/hooks/distress-queue-loader.sh | head -1
# → "...[자율운영-강..." (정상 한글 escape)
env -u PYTHONIOENCODING -u PYTHONUTF8 bash ~/.claude/hooks/distress-queue-loader.sh | head -1
# → "...[\udcec옄\udcec쑉..." (lone surrogate, 재현)
```

## 재발 방지
- 새 hook 작성 시 Python 호출 부분에 `PYTHONIOENCODING=utf-8 PYTHONUTF8=1` 명시
- 또는 글로벌 settings.json env에 항상 위 두 변수 유지
- Windows + 한국어 locale 환경의 일반 원칙: 모든 Python subprocess에 UTF-8 강제
- 한글 cwd가 아닌 ASCII cwd에서도 잠재 위험 (한국어 locale이면 발생). cwd 한글 자체는 무관, **locale + Python + 한글 출력** 조합이 핵심

## 2026-05-15 재발 사례: distress-queue-loader SessionStart 추가

### 증상
`claude --resume 30e0353e-dd0a-484c-a827-90a97f3ec5c8` 세션에서 다음 오류가 발생했다.

```text
API Error: 400 The request body is not valid JSON: invalid high surrogate in string: line 1 column 910 (char 909)
```

### 확인 결과
- 손상 세션: `C:\Users\AIcreator\.claude\projects\d--jamesclew\30e0353e-dd0a-484c-a827-90a97f3ec5c8.jsonl`
- 세션 JSONL 안 `SessionStart` attachment의 `additionalContext` 쪽에 단독 surrogate escape가 누적됨.
- 최종 스캔 결과: `raw_surrogate_escape_hits=470`
- 서브에이전트 JSONL은 surrogate hit 0으로 정상.

### 직접 원인
`harness/settings.json`에 `SessionStart` hook으로 `bash $HOME/.claude/hooks/distress-queue-loader.sh`가 추가되었지만, `env`에 다음 값이 빠져 있었다.

```json
{
  "PYTHONIOENCODING": "utf-8",
  "PYTHONUTF8": "1"
}
```

`distress-queue-loader.sh`는 Python으로 한글 `additionalContext`를 JSON escape하여 stdout으로 내보낸다. Windows 한국어 locale에서 Python stdout이 UTF-8로 강제되지 않으면 Claude Code가 hook stdout을 세션 JSONL에 lone surrogate 형태로 저장할 수 있다.

### 적용한 수정
- `harness/settings.json`의 `env`에 `PYTHONIOENCODING=utf-8`, `PYTHONUTF8=1` 추가.
- `harness/hooks/distress-queue-loader.sh` 상단에서 Python 하위 프로세스 UTF-8 강제.
- JSON escape 실패 시 한글 원문을 그대로 출력하지 않고 ASCII-only fallback을 출력하도록 변경.
- 실제 런타임 파일도 동기화:
  - `C:\Users\AIcreator\.claude\settings.json`
  - `C:\Users\AIcreator\.claude\hooks\distress-queue-loader.sh`

### 검증
전역 런타임 파일 기준으로 확인했다.

```text
global_settings_json=OK
PYTHONIOENCODING=utf-8
PYTHONUTF8=1
stdout_utf8=OK
surrogate_chars=0
json=OK
```

### 주의
새 세션의 재발은 막았지만, 이미 발생한 세션 JSONL 안의 surrogate escape 흔적은 그대로 남아 있을 수 있다. 다만 Claude Code가 해당 손상 attachment를 현재 요청 본문에 다시 포함하지 않으면 `--resume` 세션이 정상 동작할 수 있다. 실제로 세션이 정상 동작 중이면 세션 JSONL은 정리하지 않는다. 같은 400 오류가 재발하고 해당 `--resume` ID 복구가 꼭 필요할 때만, 세션 파일을 백업한 뒤 surrogate escape를 `�` 등으로 치환 정리한다. 세션 이력 수정은 사용자의 명시 승인 후에만 수행한다.
