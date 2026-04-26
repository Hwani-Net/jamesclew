---
slug: pitfall-070-statusline-settings-fixed-model-override
title: "awesome-statusline.sh가 settings.json fixed model로 input.display_name 덮어씀 — /model 일시 변경 stale 표시"
date: 2026-04-26
tier: raw
tags:
  - pitfall
  - statusline
  - awesome-statusline
  - model-display
related:
  - pitfall-026
upstream:
  - https://docs.claude.com/en/docs/claude-code/statusline
---

# 증상

사용자가 `/model` 메뉴에서 모델을 일시 변경해도 (예: opusplan → Default Opus 4.7),
statusline은 여전히 변경 전 라벨("Opus Plan Mode")을 표시.

# 원인

`~/.claude/awesome-statusline.sh` line 18~22:

```bash
SETTINGS_MODEL=$(jq -r '.model // empty' "$HOME/.claude/settings.json" 2>/dev/null)
if [[ "$SETTINGS_MODEL" == "opusplan" ]]; then
    MODEL="Opus Plan Mode"
```

= **settings.json에 `"model": "opusplan"` 박혀있으면 항상 "Opus Plan Mode" 강제**.
input.model.display_name(현재 활성 모델)을 무조건 덮어씀.

문제: `/model` 메뉴 일시 선택은 settings.json에 안 쓰여 → statusline 영구 stale.
v2.1.117 "/model 영구 지속"은 settings.json fixed value를 우선시 못 함 (override 방향 반대).

# 해결

awesome-statusline.sh에서 `SETTINGS_MODEL == "opusplan"` override 분기 제거.
**input.model.display_name(stdin JSON)만 신뢰**:

```bash
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
# (settings.json override 로직 삭제)
if [[ "$MODEL" == "Unknown" || -z "$MODEL" ]]; then
    # ~/.claude.json fallback (drift 위험 인지)
    ...
fi
```

수정 후: /model에서 일시 변경한 model이 즉시 statusline에 반영.

# 재발 방지

- statusline은 **항상 stdin JSON의 활성 model**만 신뢰. settings.json fixed value는 default 값(시작 시 적용)일 뿐, 현재 활성 model 표시 소스 아님.
- awesome-statusline 또는 다른 statusline plugin 도입 시 동일 패턴 점검.
- v2.1.119+ stdin JSON에 effort.level / thinking.enabled 추가됨 — 이런 메타 필드도 settings.json override 없이 그대로 사용.
