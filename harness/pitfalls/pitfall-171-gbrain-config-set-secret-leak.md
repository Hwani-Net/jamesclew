---
slug: pitfall-171-gbrain-config-set-secret-leak
title: "gbrain config set이 secret 값을 평문 stdout으로 echo — API 키 노출"
symptom: "gbrain config set openai_api_key sk-... 실행 시 키 전체가 stdout에 그대로 출력"
tags: [gbrain, security, secret-leak, openai, api-key]
date: 2026-05-19
severity: critical
---

## 증상

```bash
$ gbrain config set openai_api_key "$KEY"
Set openai_api_key = sk-proj-bFLqqRIReEzz...  ← 키 전체 평문 노출
```

`gbrain config show`는 `***`로 마스킹하지만, `set` 명령은 입력값을 그대로 echo. 키가 터미널·로그·session transcript에 평문 기록됨.

`bash -c "..."` 안에서 실행해도, redirect 없이 호출하면 동일하게 stdout 노출.

## 원인

gbrain CLI의 `config set` 핸들러가 사용자 입력값을 검증 후 confirmation 메시지로 그대로 출력. masking 로직 없음. 매뉴얼·`--help`에 경고 없음.

이는 gbrain 도구 자체의 디자인 결함이며 우리 환경의 hook으로 차단 불가 (PreToolUse hook은 file_path 기반).

## 해결 (즉시)

```bash
# 모든 secret-setting 명령은 stdout/stderr 모두 차단
gbrain config set <secret_key> "$VALUE" > /dev/null 2>&1

# 검증은 config show로만 (자동 마스킹됨)
gbrain config show
```

## 사고 발생 (2026-05-19)

- 대표님이 OpenAI에 $5 충전 후 새 API 키 발급
- 첫 적용 시도: `gbrain config set openai_api_key "$KEY"` (redirect 없음)
- 결과: 키 전체 (`sk-proj-bFLqq...9boA`) 평문으로 transcript에 노출
- 대응: 즉시 OpenAI 대시보드에서 노출 키 revoke + 새 키 재발급
- 2차 적용: `> /dev/null 2>&1` 적용 → 안전 처리

## 재발 방지

### 1. 헬퍼 스크립트 (영구)
`D:/jamesclew/harness/scripts/apply-openai-key.sh`에 안전 패턴 표준화:
- secret 추출 → 환경변수
- `gbrain config set ... > /dev/null 2>&1`
- `gbrain config show`로 마스킹 검증
- HTTP code로 유효성 검증 (값 노출 안 함)

### 2. 일반 원칙 — 모든 `*config set <secret>` 명령
```bash
# WRONG (값 노출)
gbrain config set openai_api_key "$KEY"
some-cli config set api_key "$SECRET"

# CORRECT (stdout/stderr 차단)
gbrain config set openai_api_key "$KEY" > /dev/null 2>&1
some-cli config set api_key "$SECRET" >/dev/null 2>&1
```

### 3. gbrain 업스트림 보고 후보
github.com/garrytan/gbrain 이슈 등록 검토:
- `config set <key> <value>`이 secret-pattern 값에 대해 자동 마스킹하도록
- 또는 `--quiet` 플래그 추가 요청

## 관련

- [[pitfall-019-gbrain-pglite-db-missing-chunk]] — DB 재구축 (오늘 같은 세션에서 발견)
- [[pitfall-147-gbrain-windows-path-aborted]] — gbrain Windows 경로 처리

## 검증 데이터 (2026-05-19 12:30 KST)

- 1차 시도 (실패, 키 노출): `Set openai_api_key = sk-proj-bFLqq...9boA`
- 2차 시도 (성공): `gbrain config set: exit=0` + `openai_api_key: ***`
- 노출된 키는 즉시 revoke, 새 키로 교체 완료
