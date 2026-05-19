---
slug: pitfall-173-settings-template-auto-revert
title: "deploy.sh가 ~/.claude/settings.json 덮어쓰며 우리 fix를 자동 revert"
symptom: "settings.json invalid JSON으로 새 세션 시작 실패. 우리가 고친 후에도 deploy.sh 실행 시 옛 invalid escape 패턴이 부활"
tags: [deploy, settings, json-escape, infrastructure, template-drift]
date: 2026-05-19
severity: high
---

## 증상

새 세션 시작 시:
```
Settings Error
C:\Users\AIcreator\.claude\settings.json
 └ Invalid or malformed JSON
Files with errors are skipped entirely, not just the invalid settings.
```

`jq` 에러:
```
jq: parse error: Invalid escape at line 546, column 13
```

이전 세션에서 이미 같은 곳 (P-171에서 발견된 `\'` invalid escape) 고쳤음에도 재발.

## 원인

`D:/jamesclew/harness/settings.json`이 **원본 템플릿**이고, `deploy.sh:35`가 매번 다음 명령 실행:

```bash
cp "$SCRIPT_DIR/settings.json" "$TARGET/settings.json"
```

즉 **deploy.sh가 ~/.claude/settings.json을 무조건 덮어쓴다**. harness/settings.json 자체에 옛 `\'` invalid escape가 그대로 있어서 deploy 한 번 돌릴 때마다 fix가 자동 revert.

### 추가 원인 — model 필드 보존도 실패
deploy.sh는 line 27-28에서 model 필드 추출 후 복원하려 함:
```bash
CURRENT_MODEL=$(jq -r '.model // empty' "$TARGET/settings.json" 2>/dev/null)
```
그러나 `~/.claude/settings.json`이 invalid JSON 상태라면 `jq` 실패 → CURRENT_MODEL=빈값 → cp 덮어쓰기 후 model 복원 안 됨. **악순환 — invalid JSON이 invalid JSON을 영구화**.

## 해결

### 즉시
1. `~/.claude/settings.json` line 546 `\"\'` → `\"'` 수정 (사용자 위치)
2. `D:/jamesclew/harness/settings.json` 동일 위치 같은 수정 (**원본 템플릿**)
3. `~/.claude/settings.json`에 `"model": "opusplan"` 다시 추가 (deploy 과정에서 사라졌음)
4. `jq` 검증: parse OK
5. `python3 json.load` 검증: parse OK

### 영구
- harness/settings.json fix가 git에 commit되어 영구화
- 다음 deploy.sh 실행 시 harness 템플릿이 이미 fix된 상태이므로 ~/.claude/settings.json에 영향 없음
- model 보존 로직도 ~/.claude/settings.json이 valid이면 정상 작동

## 재발 방지

### 1. settings.json template 검증 hook (제안)
deploy.sh가 cp 실행 전 harness/settings.json JSON 유효성 검증:
```bash
if ! jq -e . "$SCRIPT_DIR/settings.json" > /dev/null 2>&1; then
  echo "❌ harness/settings.json is invalid JSON. Aborting deploy."
  exit 1
fi
```

### 2. 모든 settings.json 편집 시 양쪽 동시 수정
- **편집해야 할 위치 2곳**:
  - `D:/jamesclew/harness/settings.json` (원본 템플릿)
  - `~/.claude/settings.json` (활성 설정)
- 하나만 고치면 deploy.sh가 덮어쓰며 fix 손실
- 가능하면 harness 원본만 고치고 deploy.sh 실행으로 동기화

### 3. JSON 표준 escape만 사용
- `\'` (single quote escape) 금지 — JSON spec 위반
- bash single-quoted string의 closing quote은 그냥 `'` (escape 불필요)
- shell escape와 JSON escape를 혼동하지 말 것

### 4. 사용자 model 영구 설정은 `model` 필드로
v2.1.144 `/model` 단일 세션 정책 → settings.json `"model"` 필드 = default
- deploy.sh 보존 로직: invalid JSON 시 실패 → 우리 fix와 함께 model도 다시 추가 필요

## 검증 데이터 (2026-05-19 14:00 KST)

### 사고 timeline
1. 13:00 — 이번 세션 첫 fix (line 535)
2. 13:30 — 이번 세션 2차 fix (line 546)
3. 13:32 — `model: opusplan` 추가
4. 13:51 — deploy.sh 실행 (gbrain 정리 후) → **harness/settings.json이 invalid 상태 그대로 덮어씀** → ~/.claude/settings.json line 546 invalid escape 부활 + model 사라짐
5. 14:00 — 대표님 새 세션 시작 시 "Settings Error" 메시지

### 부수 의문
- `harness/settings.json`은 git 추적 되지 않을 수 있음 (그러면 backup이 없음)
- 확인: `git status` / `git log` settings.json

## 관련

- [[pitfall-171-gbrain-config-set-secret-leak]] — line 535 첫 발견
- [[pitfall-172-handoff-failure-gbrain-revival]] — 같은 날 인수인계 사고
- 본 PITFALL은 P-172의 또 다른 측면 — deploy.sh가 자동 revert하는 메커니즘 자체가 인수인계 실패의 한 원인
