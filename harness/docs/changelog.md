# 하네스 변경 로그 (포인터 문서)

> 최종 갱신: 2026-06-11 | 이 파일은 2026-06-11 다이어트로 포인터화됨.

## 어디를 봐야 하나

| 목적 | 1차 소스 |
|------|----------|
| Claude Code 버전별 변경 + 하네스 영향 | `docs/claude-code-manual.md` §2 버전 히스토리 (v2.1.172 반영) |
| Raw changelog 원문 | `~/.claude/cache/changelog.md` (CLI 자동 갱신) |
| 하네스 자체 변경 이력 | git log (`D:/jamesclew` 리포) + `$OBSIDIAN_VAULT/01-jamesclaw/harness/harness_design.md` 변경 이력 표 |
| 영구 정책 결정 | `CLAUDE.md` STICKY DECISIONS |

## 과거 본문 (2026-04-23 이전)

`archive/harness-diet-2026-06-11/docs-changelog-full-2026-04-23.md` 보존 (v2.1.117~118 반영 기록 등).

## 이후 변경 시 규칙

1. CC 버전 영향은 `claude-code-manual.md` §2에 기록 (이 파일에 중복 기록 금지)
2. 하네스 영향 항목 발견 시 `audit-session.sh`에 대응 `check_` 함수 동시 추가 (CLAUDE.md 감사 동기화 규칙)
3. 설계 변경은 `harness_design.md` 변경 이력 표에 기록
