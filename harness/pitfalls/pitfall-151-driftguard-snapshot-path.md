---
slug: pitfall-151-driftguard-snapshot-path
title: verify-deploy.sh가 drift-guard v2.x의 .design-guard/snapshot.json 미인식
date: 2026-05-13
severity: medium
tags: [drift-guard, hook, p-054-related, version-drift]
---

# 증상

`~/.claude/hooks/verify-deploy.sh` line 70-72:
```bash
for D in "." "./pipelines/blog"; do
  if [ -f "$D/.drift-guard.json" ]; then DRIFT_SNAPSHOT="$D/.drift-guard.json"; break; fi
done
```

→ `.drift-guard.json` 한 가지 경로만 검색. 그러나 drift-guard v2.x (`@stayicon/drift-guard` 또는 `drift-guard` NPM 최신)는 **`.design-guard/snapshot.json` + `.design-guard/config.json` + `AGENTS.md`** 구조로 저장.

결과: `npx drift-guard init`을 정상 실행했어도 verify-deploy.sh hook이 snapshot 미인식 → 배포 시 drift check 자동 차단 비활성. P-054(stitch-design-to-code-gap) 재발 방지 무력화.

# 원인

drift-guard 패키지 v1.x → v2.x 마이그레이션 중 저장 경로가 단일 파일에서 디렉토리 구조로 변경. 하네스 hook은 v1.x 시점 코드 그대로.

# 해결

## 즉시 (sentinel 호환)
프로젝트 루트에 `.drift-guard.json` sentinel 파일을 `.design-guard/snapshot.json`의 사본으로 작성:
```bash
cd <project>
cp .design-guard/snapshot.json .drift-guard.json
```

stale 가능성 있으므로 `init` / `check` 후마다 갱신 필요.

## 정식 (hook 패치, 발표심사 전 적용 예정)
verify-deploy.sh의 검색 루프를 두 경로 모두 인식하도록 확장:
```bash
DRIFT_SNAPSHOT=""
DRIFT_DIR=""
for D in "." "./pipelines/blog" "./rebootjob" "./web" "./frontend"; do
  if [ -f "$D/.drift-guard.json" ]; then
    DRIFT_SNAPSHOT="$D/.drift-guard.json"; DRIFT_DIR="$D"; break
  fi
  if [ -f "$D/.design-guard/snapshot.json" ]; then
    DRIFT_SNAPSHOT="$D/.design-guard/snapshot.json"; DRIFT_DIR="$D"; break
  fi
done
```

# 재발 방지

- 본 pitfall을 gbrain import + AGENTS.md 자동 생성 시 `.drift-guard.json` sentinel 자동 작성 hook 추가 후보
- drift-guard 패키지 버전 명시: `@stayicon/drift-guard` 또는 `drift-guard` (확인 필요)
- 매 세션 시작 시 `claude mcp list` 처럼 `drift-guard --version` 체크 후 hook 호환 분기

# 관련

- P-054 (Stitch 디자인 → 코드 변환 시 세부 요소 누락)
- P-149 (Step 0 Stitch 건너뜀)
- P-150 (도구 명시 시 매뉴얼 우선)
- `~/.claude/hooks/verify-deploy.sh` line 66-84
- `~/.claude/hooks/stitch-drift-guard.sh` line 52 — 동일 mismatch (PostToolUse 단계에서도 `.drift-guard.json` 만 체크)
