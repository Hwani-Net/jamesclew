---
name: 사용자 이메일 vs 디바이스 계정 혼동
description: CLAUDE.md userEmail 필드를 디바이스/서비스 계정으로 잘못 추정하지 말 것 — 명시적 확인 필수
type: pitfall
tags: [communication, email, play-store, twa, identity]
---

# pitfall-072: 사용자 이메일 vs 디바이스 계정 혼동

## 증상 (Symptom)

- Play Console / Play Store / Firebase / GCP 등 **계정 다중 사용 환경**에서 안내 시
- CLAUDE.md `userEmail` 필드(예: `dlwptjq2@gmail.com`)를 디바이스 또는 작업 계정으로 잘못 추정하여 안내
- 대표님이 정정 ("아니, 그 계정 아니야") 발생

## 원인 (Root Cause)

- 사용자는 **여러 Google 계정**을 용도별로 분리 운영 (개인 / 개발 / 테스터 / 결제 등)
- CLAUDE.md `userEmail`은 **연락용/기본 ID**일 뿐, 다른 작업의 active account가 아님
- Play Store/GCP 등은 작업 컨텍스트마다 active account가 다름 (예: 이번 케이스 — gcloud=hwanizero01, 디바이스=hwanizero01, CLAUDE.md=dlwptjq2)
- 추측으로 "userEmail = 디바이스 계정"이라고 가정하면 70% 확률로 틀림

## 해결 (Solution)

### 즉시
1. 정정 받으면 즉시 사과 없이 정확한 계정으로 가이드 재작성
2. 새 계정이 작업 컨텍스트(Play Console 테스터 목록, GCP IAM 등)에 등록되어 있는지 확인 후 안내

### 재발 방지
1. **계정 안내 시 단정 금지** — "어느 계정으로 진행하시나요?" 또는 "디바이스/Play Store 로그인 계정 알려주세요" 먼저 확인
2. CLAUDE.md `userEmail`은 **연락 채널**로만 사용 (텔레그램 알림 등). 작업 계정 추정 금지
3. **gcloud `--account` 인자**가 명시된 명령은 그것이 작업 계정 (이 세션에서는 `hwanizero01@gmail.com`이 모든 gcloud 호출에 사용됨 → 디바이스 계정도 동일할 가능성 높음)
4. Play Console 테스터 목록에 여러 계정이 보이면 "어느 계정이 디바이스에서 활성인가요?" 명시 확인

## 재발 이력

- 2026-04-26 (최초): TWA 테스트 설치 안내 시 CLAUDE.md `dlwptjq2@gmail.com`을 디바이스 계정으로 잘못 추정. 실제는 `hwanizero01@gmail.com` (gcloud 작업 계정과 동일).

## 참조

- 관련 컨텍스트 단서: gcloud 모든 명령에 `--account=hwanizero01@gmail.com` 사용. 이 패턴이 디바이스 계정 추정의 더 강한 신호였음.
