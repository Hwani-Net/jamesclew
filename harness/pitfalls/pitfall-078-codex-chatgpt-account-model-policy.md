---
slug: pitfall-078-codex-chatgpt-account-model-policy
title: Codex CLI ChatGPT 계정 모델 정책 + auth.json 부재
date: 2026-04-28
type: pitfall
severity: high
tags: [codex, chatgpt, auth, model-policy, codex-rotate]
---

# pitfall-078 — Codex CLI ChatGPT 계정 모델 정책 + auth.json 부재

## 증상
1. `codex exec "..."` 호출 시 모든 모델 거절:
   - `gpt-5.2-codex`, `gpt-5`, `o3`, `gpt-4o` 모두 `400 Bad Request: "model not supported when using Codex with a ChatGPT account"` 에러
2. `codex-rotate.sh` 호출 시 6+1=7개 계정 모두 동일 에러 (로테이션 무효)
3. `~/.codex/auth.json` 파일 자체가 부재 가능 (백업 `~/.codex-accounts/`만 존재)
4. `Not inside a trusted directory and --skip-git-repo-check was not specified` 에러도 동반

## 원인
1. **모델 정책**: ChatGPT 계정 (Plus/Team/Pro)으로 인증된 Codex CLI는 일반 GPT 모델(`gpt-5`, `gpt-4o`, `o3`, `gpt-5.2-codex` 등) 호출 불가. **`gpt-5.4`** 만 동작 (2026-04-28 검증).
2. **auth.json 손실**: `~/.codex/auth.json`이 codex 자체 동작 또는 외부 도구로 삭제된 경우. `codex-rotate.sh`는 매 호출 시 백업에서 복원하나, 어떤 백업도 모델 거절을 해결하지 않음 (정책은 OpenAI 측).
3. **Trusted dir**: `codex exec`는 git repo 안에서만 실행. 비-git 디렉토리에서 호출 시 차단. `--skip-git-repo-check` 옵션은 `codex exec`에 없음 → `cd <git-repo>` 후 호출 필요.

## 해결
1. **auth.json 복원**: `cp ~/.codex-accounts/account1.json ~/.codex/auth.json`
2. **모델 명시**: `codex exec -m gpt-5.4 "..."` (필수)
3. **git repo dir 사용**: `cd D:/jamesclew && codex exec ...` (또는 다른 git 초기화된 디렉토리)
4. **codex-rotate.sh 갱신**: line 43 `OUTPUT=$(codex exec -m gpt-5.4 "$PROMPT" 2>&1)` + 모델 거절 감지 시 다음 계정 시도 로직 추가 (2026-04-28 적용 완료)
5. **이미지 첨부**: `-i FILE` 옵션은 prompt를 stdin으로 전달해야 동작 — `echo "PROMPT" | codex exec -m gpt-5.4 -i FILE`

## 재발 방지
- Codex CLI 사용 모든 스크립트는 `-m gpt-5.4` 명시 필수
- 새 코덱스 버전 출시 시 사용 가능 모델 재확인 (정책 변경 가능성)
- `codex auth status` 또는 `~/.codex/auth.json` 존재 여부 정기 검사
- /codex-refresh 또는 /codex:setup 14일마다 호출 (PITFALL-057과 연관)

## 1차 출처
- 직접 검증 (2026-04-28 16:30~16:45):
  - `gpt-5.2-codex`: 400 에러
  - `gpt-5`: 400 에러
  - `o3`: 400 에러
  - `gpt-4o`: 400 에러
  - **`gpt-5.4`: 정상 응답** ✅

## 관련
- pitfall-057: Codex CLI 14일 OAuth 토큰 만료
- /codex-refresh skill: 토큰 재로그인 가이드
