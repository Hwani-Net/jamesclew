#!/bin/bash
# bootstrap-vault.sh — Obsidian Vault directory structure seeder (idempotent)
# Usage:
#   bash bootstrap-vault.sh /path/to/vault
#   OBSIDIAN_VAULT=/path/to/vault bash bootstrap-vault.sh
#   (falls back to ~/.harness.env OBSIDIAN_VAULT if neither set)

set -euo pipefail

# ─── Resolve vault path ───
VAULT="${1:-}"

if [[ -z "$VAULT" ]]; then
  VAULT="${OBSIDIAN_VAULT:-}"
fi

if [[ -z "$VAULT" ]]; then
  ENV_FILE="$HOME/.harness.env"
  if [[ -f "$ENV_FILE" ]]; then
    VAULT="$(grep -E '^OBSIDIAN_VAULT=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' | tr -d "'")"
  fi
fi

if [[ -z "$VAULT" ]]; then
  echo "ERROR: OBSIDIAN_VAULT not set. Pass as argument or set env var." >&2
  echo "  Usage: bash bootstrap-vault.sh /path/to/vault" >&2
  exit 1
fi

# Normalize: strip trailing slash
VAULT="${VAULT%/}"

echo "══════════════════════════════════════════"
echo "  Obsidian Vault Bootstrap"
echo "  Target: $VAULT"
echo "══════════════════════════════════════════"

# ─── Helper: make dir + optional README (idempotent) ───
seed_dir() {
  local dir="$1"
  local readme_content="${2:-}"

  mkdir -p "$dir"

  if [[ -n "$readme_content" && ! -f "$dir/README.md" ]]; then
    printf '%s\n' "$readme_content" > "$dir/README.md"
    echo "  [created] $dir/README.md"
  elif [[ -n "$readme_content" ]]; then
    echo "  [exists]  $dir/README.md"
  fi
}

# ─── Helper: .gitkeep only (no README) ───
seed_dir_gitkeep() {
  local dir="$1"
  mkdir -p "$dir"
  if [[ ! -f "$dir/.gitkeep" ]]; then
    touch "$dir/.gitkeep"
    echo "  [created] $dir/.gitkeep"
  else
    echo "  [exists]  $dir/.gitkeep"
  fi
}

echo ""
echo "── Tier 0: Inbox ──────────────────────────"
seed_dir_gitkeep "$VAULT/00-inbox"

echo ""
echo "── Tier 1: JamesClaw ──────────────────────"
seed_dir "$VAULT/01-jamesclaw" "# JamesClaw

하네스 설계, 세션, 리서치, 리뷰, 문서.
"
seed_dir "$VAULT/01-jamesclaw/harness" "# Harness Design

하네스 설계 문서, 버전 이력, hook/rule 변경 로그.

## 주요 파일
- \`harness_design.md\` — 전체 설계 및 변경 이력
- \`docs/\` — Claude Code 매뉴얼 미러
"
seed_dir "$VAULT/01-jamesclaw/research" "# Research

도구 선정, 리서치 결과, 기술 조사.
"
seed_dir "$VAULT/01-jamesclaw/reviews" "# Reviews

외부 평가, 피드백, QA 결과.
"
seed_dir "$VAULT/01-jamesclaw/sessions" "# Sessions

compact 전 저장된 세션 요약.
"
seed_dir "$VAULT/01-jamesclaw/docs" "# Docs

Claude Code 매뉴얼 미러 및 참조 문서.
"

echo ""
echo "── Tier 2: Projects ───────────────────────"
seed_dir "$VAULT/02-projects" "# Projects

프로젝트별 문서. 각 프로젝트는 하위 폴더로 분리.

## 폴더 규칙
- \`{project-slug}/\` — 프로젝트별 PRD, 설계, 배포 기록
"

echo ""
echo "── Tier 3: Knowledge ──────────────────────"
seed_dir "$VAULT/03-knowledge" "# Knowledge

영구 지식 베이스. 도구, 패턴, 의사결정 기준.
"

echo ""
echo "── Tier 4: Personal ───────────────────────"
seed_dir "$VAULT/04-personal" "# Personal

개인 메모, 아이디어, 일지.
"

echo ""
echo "── Tier 5: Wiki (BASB 3-tier) ─────────────"
seed_dir "$VAULT/05-wiki" "# Wiki — BASB Progressive Summarization

3계층 지식 구조. 상세: rules/secondbrain-tiers.md

| Layer | 폴더 | 정의 |
|-------|------|------|
| Raw | sources/, entities/ | 외부 원문·스펙. 변형 최소 |
| Distilled | distilled/, concepts/, analyses/ | 구조 정리된 요약·재해석 |
| Synthesized | synthesized/ | 내 관점의 통합 주장 |
"

seed_dir "$VAULT/05-wiki/sources" "---
tier: raw
---
# Sources

외부 원문 수집 (Perplexity/Tavily 결과, URL 추출, 공식 문서).

## 파일 명명 규칙
\`YYYY-MM-DD-{slug}.md\`

## frontmatter 필수 필드
\`\`\`yaml
---
title: \"...\"
tier: raw
date: YYYY-MM-DD
source: https://...
---
\`\`\`
"

seed_dir "$VAULT/05-wiki/entities" "---
tier: raw
---
# Entities

사람, 회사, 제품 등 고유 엔티티 프로파일.

## frontmatter 필수 필드
\`\`\`yaml
---
title: \"...\"
tier: raw
date: YYYY-MM-DD
entity_type: person | company | product | tool
---
\`\`\`
"

seed_dir "$VAULT/05-wiki/distilled" "---
tier: distilled
---
# Distilled

Raw 소스를 읽고 재구성한 요약·재해석.

## 승격 조건
- 원문 인용 < 30%
- 나만의 정리 순서/표/도식 있음
- \"내 생각\" 1문단 포함
- 관련 링크 1개 이상

## frontmatter 필수 필드
\`\`\`yaml
---
title: \"...\"
tier: distilled
date: YYYY-MM-DD
summary: \"3줄 요약\"
---
\`\`\`
"

seed_dir "$VAULT/05-wiki/concepts" "---
tier: distilled
---
# Concepts

개념 정리 및 용어 사전.

## frontmatter 필수 필드
\`\`\`yaml
---
title: \"...\"
tier: distilled
date: YYYY-MM-DD
summary: \"한 줄 정의\"
---
\`\`\`
"

seed_dir "$VAULT/05-wiki/analyses" "---
tier: distilled
---
# Analyses

비교 분석, 경쟁 분석, 트렌드 분석.

## frontmatter 필수 필드
\`\`\`yaml
---
title: \"...\"
tier: distilled
date: YYYY-MM-DD
summary: \"분석 목적 + 결론 1줄\"
---
\`\`\`
"

seed_dir "$VAULT/05-wiki/synthesized" "---
tier: synthesized
---
# Synthesized

Distilled 2개 이상 통합 + 내 고유 관점의 주장.

## 승격 조건
- Distilled 소스 2+ 참조 (backlink 필수)
- 고유한 결론/주장/가설
- 행동 지침·체크리스트·의사결정 기준
- 3개월 후 읽어도 유용한 관점

## frontmatter 필수 필드
\`\`\`yaml
---
title: \"...\"
tier: synthesized
date: YYYY-MM-DD
summary: \"핵심 주장 1-2줄\"
---
\`\`\`
"

echo ""
echo "── Tier 6: Raw ─────────────────────────────"
seed_dir_gitkeep "$VAULT/06-raw"

echo ""
echo "══════════════════════════════════════════"

# ─── Final summary ───
TOTAL_DIRS=$(find "$VAULT" -type d | wc -l)
echo "  Done. Total directories: $TOTAL_DIRS"
echo "  Vault: $VAULT"
echo "══════════════════════════════════════════"
