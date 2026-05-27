---
id: pitfall-222
slug: hybrid-sync-architecture
date: 2026-05-26
severity: high
tags: [wsl2, openclaw, smartreview, sync, firebase, p-218]
---

# PITFALL-222: OpenClaw WSL2 ↔ Windows smartreview 환경 분리 위반

## 증상
nyongjong(orchestrator)이 smartreview 홈 개선 작업 지시 → P-218(WSL2 경로 명시 강제)에 의해 Windows 직접 접근 차단. OpenClaw 봇이 Windows 측 `D:/AI 비즈니스/smartreview/public/`을 직접 편집 시도해도 실제 반영이 안 되거나 P-218 위반 경고 발생.

## 원인
- WSL2 OpenClaw 환경과 Windows smartreview 배포 환경이 완전히 분리되어 있음
- 봇이 Windows 경로(`/mnt/d/`, `D:/`)에 산출물을 직접 쓰려 해도 P-218 룰이 차단
- 두 환경 간 자동 동기화 메커니즘 없이는 WSL2 작업이 Firebase에 도달 불가

## 해결 (2026-05-26 구축 완료)
단방향 sync 인프라 구축:
1. **WSL2 source-of-truth**: `/home/creator/openclaw-smartreview/public/` — OpenClaw가 여기서만 작업
2. **sync 스크립트**: `/home/creator/.openclaw/scripts/smartreview-sync.sh` (rsync, --delete 없음)
3. **systemd user units**: `smartreview-sync.path` (즉시) + `smartreview-sync.timer` (5분 fallback)
4. **Windows target**: `/mnt/d/AI 비즈니스/smartreview/public/` — sync 결과만, 직접 편집 금지
5. **Firebase deploy**: main 세션이 Windows에서 직접 실행 (OpenClaw 권한 없음)

## 재발 방지
- AGENTS.md 3개(workspace/workspace-codex/workspace-claude)에 §P-222
