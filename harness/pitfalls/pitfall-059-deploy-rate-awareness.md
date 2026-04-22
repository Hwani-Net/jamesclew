---
slug: pitfall-059-deploy-rate-awareness
title: Agent Teams 진화 루프 설계 시 배포 리밋 미고려
type: pitfall
date: 2026-04-20
tags: [deploy, rate-limit, cloud-build, play-store, agent-teams]
---

## 증상
BiteLog 진화 루프용 슬래시 커맨드(`/bitelog-evolve`) 첫 설계에서 사이클마다 자동 배포 + Play Store 업로드를 전제. 대표님 지적: "배포 자체가 리밋에 걸려 막히는 경우 없을까?"

## 원인
Cloud Build 무료 티어(월 2,500 build-minutes) 및 Play Store 버전코드 누적을 계산하지 않고 무제한 사이클 반복을 가정. Next.js 빌드 평균 5분 기준 월 500회가 한계 — 하루 20회 배포 × 30일 = 600회면 과금 발생. 진화 루프처럼 자동 N사이클 돌리면 쉽게 초과.

실측 수치:
- **Cloud Build**: 2,500 min/월 무료, 초과 시 $0.003/min (standard)
- **Play Store Android Publisher API**: 일일 200,000 req/앱, 분당 3,000 query — 사실상 무제한이나 versionCode 난사로 트랙 히스토리 오염
- **Firebase App Hosting Developer Connect**: 600 req/min — 연속 push 시 트리거 가능 (GitHub Issue #8711)

## 해결
`/bitelog-evolve` 프롬프트에 4가지 배포 전략 필수 포함:
1. **사이클 내 push 1회 (배칭)**: Builder는 로컬 commit만, Shipper가 사이클 종료 시 일괄 push
2. **쿨다운 10분**: 직전 push 이후 최소 10분 대기
3. **dry-run 기본**: `--deploy` 명시 없으면 로컬 빌드까지만
4. **Play Store N사이클 배치**: Internal 업로드는 기본 5사이클마다 1회. `--play-upload`로 강제
5. **사용량 모니터링**: 매 사이클 시작 시 `gcloud builds list --project=bite-log-app --format="value(createTime)"`로 이번 달 누적 확인, 400회 초과 시 자동 dry-run 전환

## 재발 방지
- 모든 "자율 루프" 성 Agent Teams 커맨드 설계 시 **외부 서비스 과금/리밋 체크리스트 필수**:
  - 빌드 엔진 (Cloud Build / GitHub Actions) 월간 한도
  - 배포 플랫폼 (App Hosting / Play Store / App Store) 속도 제한
  - API 키 일일 한도 (OpenAI, Perplexity, Tavily 등)
- 진화/반복 루프는 **dry-run 기본 + 명시 opt-in**으로 배포 전환 (무방비 자동 배포 금지)
- 사이클 간 쿨다운(≥5분)을 하드코딩하여 큐 오염 방지
