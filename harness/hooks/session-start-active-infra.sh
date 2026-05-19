#!/bin/bash
# session-start-active-infra.sh — SessionStart hook
# 매 세션 시작 시 활성 자율 인프라 + 핵심 정책 alert. 다음 세션 메인이 즉시 인지.
# CLAUDE.md '활성 자율 인프라' 섹션과 동기화 (1차 소스: CLAUDE.md).

set -e

MSG="[ACTIVE INFRA] hook: cdp-auto-ensure(v2)+cdp-mark-fail / agentmemory-mirror-obsidian / pre-compact-snapshot. LIVE: multi-blog-personal.web.app (13p, source: D:/AI 비즈니스/smartreview) + gpt-korea.com/reviews (rewrite proxy). 핵심 정책: P-163(로컬 보조전용) / P-167(흐름 중단 금지) / P-168(자율 결정·결재 5건만) / P-169(CDP 자율). CLAUDE.md 'STICKY DECISIONS > 활성 자율 인프라' 섹션이 1차 소스 — 신규 hook/인프라 추가 시 그 섹션 동시 등록 필수."

# stdout JSON for additionalContext injection
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$MSG"
