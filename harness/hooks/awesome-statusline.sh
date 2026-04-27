#!/bin/bash
# ============================================================================
# Awesome Statusline - FULL (Long) Mode
# ============================================================================
# Line 1: 🤖 Model | 🎨 Style | ✅ Git (↑ahead ↓behind) | 🐍 Env
# Line 2: 📂 full path 🌿(branch) | 💰 cost | ⏰ duration
# Line 3: 🧠 Context bar 40 blocks - MochaMaroon→LatteMaroon(40%)→Red(80-100%)
# Line 4: 🚀 5H Limit bar 40 blocks - Lavender→Lavender(40%)→Blue(80%)→Red(100%)
# Line 5: 🌟 7D Limit bar 40 blocks - Yellow→Yellow(40%)→Green(80%)→Red(100%)
# 5H Reset: "(Resets in 2h15m)" | 7D Reset: "(Resets Jan 21 at 2pm)"
# ============================================================================

input=$(cat)

# stdin JSON의 활성 모델만 신뢰 (settings.json 읽지 않음 — PITFALL-070 원칙)
# opusplan 모드에서 Sonnet 표시는 "현재 실행 단계, plan 단계 아님"의 정확한 신호
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

if [[ "$MODEL" == "Unknown" || -z "$MODEL" ]]; then
    CLAUDE_JSON_MODEL=$(jq -r '.teammateDefaultModel // empty' "$HOME/.claude.json" 2>/dev/null)
    case "$CLAUDE_JSON_MODEL" in
        opus)   MODEL="Claude Opus" ;;
        sonnet) MODEL="Claude Sonnet" ;;
        haiku)  MODEL="Claude Haiku" ;;
        *)      MODEL="Unknown" ;;
    esac
fi
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
CURRENT_USAGE=$(echo "$input" | jq -r '.context_window.current_usage // null')
OUTPUT_STYLE=$(echo "$input" | jq -r '.output_style.name // ""')
TOTAL_COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
TOTAL_DURATION=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# ============================================================================
# Colors
# ============================================================================
RESET="\033[0m"
BOLD="\033[1m"

cat_teal() { echo -e "\033[38;2;148;226;213m"; }
cat_pink() { echo -e "\033[38;2;245;194;231m"; }
cat_peach() { echo -e "\033[38;2;250;179;135m"; }
cat_green() { echo -e "\033[38;2;166;227;161m"; }
cat_subtext() { echo -e "\033[38;2;166;173;200m"; }
cat_lavender() { echo -e "\033[38;2;180;190;254m"; }
cat_yellow() { echo -e "\033[38;2;249;226;175m"; }
cat_overlay() { echo -e "\033[38;2;108;112;134m"; }
latte_green() { echo -e "\033[38;2;64;160;43m"; }
latte_red() { echo -e "\033[38;2;210;15;57m"; }
latte_yellow() { echo -e "\033[38;2;223;142;29m"; }
latte_pink() { echo -e "\033[38;2;234;118;203m"; }
latte_maroon() { echo -e "\033[38;2;230;69;83m"; }
latte_sky() { echo -e "\033[38;2;4;165;229m"; }
latte_blue() { echo -e "\033[38;2;30;102;245m"; }
mocha_maroon() { echo -e "\033[38;2;235;160;172m"; }
pure_black() { echo -e "\033[38;2;0;0;0m"; }

# ============================================================================
# Gradient Functions
# ============================================================================
# Context gradient: Mocha Maroon(0%) → Latte Maroon(40%) → Latte Red(80-100%)
get_context_gradient_color() {
    local pct=$1
    local r g b

    if [[ $pct -lt 40 ]]; then
        # Mocha Maroon (#eba0ac) → Latte Maroon (#e64553)
        local t=$((pct * 100 / 40))
        r=$((235 + (230 - 235) * t / 100))
        g=$((160 + (69 - 160) * t / 100))
        b=$((172 + (83 - 172) * t / 100))
    elif [[ $pct -lt 80 ]]; then
        # Latte Maroon (#e64553) → Latte Red (#d20f39)
        local t=$(((pct - 40) * 100 / 40))
        r=$((230 + (210 - 230) * t / 100))
        g=$((69 + (15 - 69) * t / 100))
        b=$((83 + (57 - 83) * t / 100))
    else
        # Latte Red (#d20f39) - hold at 80-100%
        r=210; g=15; b=57
    fi
    echo "$r;$g;$b"
}

# 5H: Mocha Lavender(0%) → Latte Lavender(40%) → Latte Blue(80%) → Latte Red(100%)
get_usage_gradient_color() {
    local pct=$1
    local r g b
    if [[ $pct -lt 40 ]]; then
        # Mocha Lavender (#b4befe) → Latte Lavender (#7287fd)
        local t=$((pct * 100 / 40))
        r=$((180 + (114 - 180) * t / 100))
        g=$((190 + (135 - 190) * t / 100))
        b=$((254 + (253 - 254) * t / 100))
    elif [[ $pct -lt 80 ]]; then
        # Latte Lavender (#7287fd) → Latte Blue (#1e66f5)
        local t=$(((pct - 40) * 100 / 40))
        r=$((114 + (30 - 114) * t / 100))
        g=$((135 + (102 - 135) * t / 100))
        b=$((253 + (245 - 253) * t / 100))
    else
        # Latte Blue (#1e66f5) → Latte Red (#d20f39)
        local t=$(((pct - 80) * 100 / 20))
        r=$((30 + (210 - 30) * t / 100))
        g=$((102 + (15 - 102) * t / 100))
        b=$((245 + (57 - 245) * t / 100))
    fi
    echo "$r;$g;$b"
}

# 7D: Mocha Yellow(0%) → Latte Yellow(40%) → Latte Green(80%) → Latte Red(100%)
get_usage_7d_gradient_color() {
    local pct=$1
    local r g b
    if [[ $pct -lt 40 ]]; then
        # Mocha Yellow (#f9e2af) → Latte Yellow (#df8e1d)
        local t=$((pct * 100 / 40))
        r=$((249 + (223 - 249) * t / 100))
        g=$((226 + (142 - 226) * t / 100))
        b=$((175 + (29 - 175) * t / 100))
    elif [[ $pct -lt 80 ]]; then
        # Latte Yellow (#df8e1d) → Latte Green (#40a02b)
        local t=$(((pct - 40) * 100 / 40))
        r=$((223 + (64 - 223) * t / 100))
        g=$((142 + (160 - 142) * t / 100))
        b=$((29 + (43 - 29) * t / 100))
    else
        # Latte Green (#40a02b) → Latte Red (#d20f39)
        local t=$(((pct - 80) * 100 / 20))
        r=$((64 + (210 - 64) * t / 100))
        g=$((160 + (15 - 160) * t / 100))
        b=$((43 + (57 - 43) * t / 100))
    fi
    echo "$r;$g;$b"
}

generate_bar() {
    local pct=$1
    local width=$2
    local type=$3
    local bar=""
    local filled=$(( (pct * width + 50) / 100 ))
    [[ $filled -gt $width ]] && filled=$width

    local end_color
    case "$type" in
        context) end_color=$(get_context_gradient_color "$pct") ;;
        7d) end_color=$(get_usage_7d_gradient_color "$pct") ;;
        *) end_color=$(get_usage_gradient_color "$pct") ;;
    esac

    for ((i=0; i<filled; i++)); do
        local block_pct=$((i * 100 / width))
        local color
        case "$type" in
            context) color=$(get_context_gradient_color "$block_pct") ;;
            7d) color=$(get_usage_7d_gradient_color "$block_pct") ;;
            *) color=$(get_usage_gradient_color "$block_pct") ;;
        esac
        bar+="\033[38;2;${color}m█"
    done

    for ((i=0; i<width-filled; i++)); do
        bar+="\033[38;2;${end_color}m░"
    done

    echo -e "$bar$RESET"
}

# ============================================================================
# Line 1: Model | Style | Git Status (↑ahead ↓behind) | Env
# ============================================================================

# Model (bold)
MODEL_DISPLAY="🤖 ${BOLD}$(cat_teal)${MODEL}${RESET}"

# Output style (moved to second position)
STYLE_DISPLAY=""
[[ -n "$OUTPUT_STYLE" ]] && STYLE_DISPLAY="🎨 $(cat_peach)${OUTPUT_STYLE}${RESET}"

# Git status with ahead/behind arrows
GIT_STATUS_DISPLAY=""
cd "$CURRENT_DIR" 2>/dev/null
if git rev-parse --git-dir > /dev/null 2>&1; then
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    # Get ahead/behind count relative to upstream
    AHEAD_BEHIND=""
    if git rev-parse --abbrev-ref '@{upstream}' &>/dev/null; then
        COUNTS=$(git rev-list --left-right --count HEAD...'@{upstream}' 2>/dev/null)
        if [[ -n "$COUNTS" ]]; then
            AHEAD=$(echo "$COUNTS" | awk '{print $1}')
            BEHIND=$(echo "$COUNTS" | awk '{print $2}')
            [[ "$AHEAD" -gt 0 ]] && AHEAD_BEHIND="${AHEAD_BEHIND}$(latte_sky)↑${AHEAD}${RESET}"
            [[ "$BEHIND" -gt 0 ]] && AHEAD_BEHIND="${AHEAD_BEHIND}$(latte_pink)↓${BEHIND}${RESET}"
        fi
    fi

    if [[ "$STAGED" -eq 0 && "$UNSTAGED" -eq 0 && "$UNTRACKED" -eq 0 ]]; then
        GIT_STATUS_DISPLAY="$(cat_green)✅ git clean${RESET}"
        [[ -n "$AHEAD_BEHIND" ]] && GIT_STATUS_DISPLAY="${GIT_STATUS_DISPLAY} ${AHEAD_BEHIND}"
    else
        STATUS=""
        [[ "$STAGED" -gt 0 ]] && STATUS="${STATUS}+${STAGED}"
        [[ "$UNSTAGED" -gt 0 ]] && STATUS="${STATUS}!${UNSTAGED}"
        [[ "$UNTRACKED" -gt 0 ]] && STATUS="${STATUS}?${UNTRACKED}"
        GIT_STATUS_DISPLAY="$(latte_yellow)📝 dirty ${STATUS}${RESET}"
        [[ -n "$AHEAD_BEHIND" ]] && GIT_STATUS_DISPLAY="${GIT_STATUS_DISPLAY} ${AHEAD_BEHIND}"
    fi
else
    GIT_STATUS_DISPLAY="$(cat_overlay)no git${RESET}"
fi

# Conda env
ENV_DISPLAY=""
if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    ENV_DISPLAY="🐍 $(cat_pink)${CONDA_DEFAULT_ENV}${RESET}"
else
    ENV_DISPLAY="$(cat_overlay)no env${RESET}"
fi

# Build Line 1: Model | Style | Git | Env
LINE1="${MODEL_DISPLAY}"
[[ -n "$STYLE_DISPLAY" ]] && LINE1="${LINE1} | ${STYLE_DISPLAY}"
LINE1="${LINE1} | ${GIT_STATUS_DISPLAY} | ${ENV_DISPLAY}"

# ============================================================================
# Line 2: Directory + Branch | Cost | Duration
# ============================================================================

# Directory (full path, no ~)
DIR_DISPLAY="📂 $(cat_subtext)${CURRENT_DIR}${RESET}"

# Git branch
BRANCH_DISPLAY=""
cd "$CURRENT_DIR" 2>/dev/null
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    [[ -n "$BRANCH" ]] && BRANCH_DISPLAY=" $(latte_green)🌿(${BRANCH})${RESET}"
fi

# Cost (same color as directory)
COST_DISPLAY=""
if [[ "$TOTAL_COST" != "0" && -n "$TOTAL_COST" ]]; then
    COST_FMT=$(printf "%.2f" "$TOTAL_COST")
    COST_DISPLAY="💰 $(cat_subtext)${COST_FMT}\$${RESET}"
else
    COST_DISPLAY="💰 $(cat_overlay)0.00\$${RESET}"
fi

# Duration
DURATION_DISPLAY=""
if [[ "$TOTAL_DURATION" != "0" && -n "$TOTAL_DURATION" ]]; then
    DURATION_SEC=$((TOTAL_DURATION / 1000))
    if [[ $DURATION_SEC -ge 3600 ]]; then
        DURATION_FMT="$((DURATION_SEC / 3600))h$((DURATION_SEC % 3600 / 60))m"
    else
        DURATION_FMT="$((DURATION_SEC / 60))m"
    fi
    DURATION_DISPLAY="⏰ $(cat_subtext)${DURATION_FMT}${RESET}"
else
    DURATION_DISPLAY="⏰ $(cat_overlay)0m${RESET}"
fi

LINE2="${DIR_DISPLAY}${BRANCH_DISPLAY} | ${COST_DISPLAY} | ${DURATION_DISPLAY}"

# ============================================================================
# Line 3: Context (20 blocks)
# ============================================================================

CONTEXT_PERCENT=0
CURRENT_TOKENS=0
if [[ "$CURRENT_USAGE" != "null" && -n "$CURRENT_USAGE" ]]; then
    INPUT_TOKENS=$(echo "$CURRENT_USAGE" | jq -r '.input_tokens // 0')
    CACHE_CREATE=$(echo "$CURRENT_USAGE" | jq -r '.cache_creation_input_tokens // 0')
    CACHE_READ=$(echo "$CURRENT_USAGE" | jq -r '.cache_read_input_tokens // 0')
    CURRENT_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    [[ "$CONTEXT_SIZE" -gt 0 ]] && CONTEXT_PERCENT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
fi

# Format tokens as k
TOKENS_K=$((CURRENT_TOKENS / 1000))
CONTEXT_K=$((CONTEXT_SIZE / 1000))

CTX_BAR=$(generate_bar "$CONTEXT_PERCENT" 40 "context")
CTX_END_COLOR=$(get_context_gradient_color "$CONTEXT_PERCENT")
LINE3="🧠 $(mocha_maroon)Context${RESET}  ${CTX_BAR} ${BOLD}\033[38;2;${CTX_END_COLOR}m${CONTEXT_PERCENT}% used${RESET} (${TOKENS_K}k/${CONTEXT_K}k)"

# ============================================================================
# Lines 4-5: Usage 5H and 7D (20 blocks)
# ============================================================================

get_usage_data() {
    local token
    # macOS: Keychain
    token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    # Windows fallback: credentials file
    if [[ -z "$token" ]] && [[ -f "$HOME/.claude/.credentials.json" ]]; then
        token=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
    fi
    [[ -z "$token" ]] && return 1

    local cache_file="/tmp/.claude_usage_cache"
    local cache_fresh="/tmp/.claude_usage_fresh"
    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        # Fresh cache (30min) — use directly
        [[ "$file_age" -lt 1800 ]] && cat "$cache_file" && return 0
    fi
    # Throttle: don't retry more than once per 60 seconds
    if [[ -f "$cache_fresh" ]]; then
        local fresh_age=$(($(date +%s) - $(stat -c %Y "$cache_fresh" 2>/dev/null || stat -f %m "$cache_fresh" 2>/dev/null || echo 0)))
        if [[ "$fresh_age" -lt 600 ]]; then
            # Still throttled — return stale cache if available
            [[ -f "$cache_file" ]] && cat "$cache_file" && return 0
            return 1
        fi
    fi
    touch "$cache_fresh"

    local response
    response=$(curl -s --max-time 3 \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "anthropic-beta: oauth-2025-04-20" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

    if [[ -n "$response" ]] && echo "$response" | jq -e '.five_hour' &>/dev/null; then
        echo "$response" > "$cache_file"
        echo "$response"
        return 0
    fi
    # Rate limited or error — use stale cache if exists
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return 0
    fi
    # No cache at all — write a throttle file to prevent rapid retries
    echo '{"five_hour":{"utilization":0},"seven_day":{"utilization":0}}' > "$cache_file"
    return 1
}

# Format reset time as "in 2h15m" for 5H
format_time_remaining() {
    local ts="$1"
    [[ -z "$ts" || "$ts" == "null" ]] && return
    local reset_epoch=""
    # Check if input is epoch number (digits only)
    if [[ "$ts" =~ ^[0-9]+$ ]]; then
        reset_epoch="$ts"
    else
        # ISO string parsing
        local normalized=$(echo "$ts" | sed 's/\.[0-9]*//')
        local mac_ts=$(echo "$normalized" | sed 's/+00:00/+0000/; s/Z$/+0000/; s/+\([0-9][0-9]\):\([0-9][0-9]\)/+\1\2/')
        reset_epoch=$(date -d "$normalized" "+%s" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$mac_ts" "+%s" 2>/dev/null)
    fi
    [[ -z "$reset_epoch" ]] && return
    local now_epoch=$(date +%s)
    local remaining=$((reset_epoch - now_epoch))
    [[ $remaining -lt 0 ]] && remaining=0
    local hours=$((remaining / 3600))
    local minutes=$(((remaining % 3600) / 60))
    echo "in ${hours}h${minutes}m"
}

# Format reset time as "Jan 21 at 2pm" for 7D
format_reset_datetime() {
    local ts="$1"
    [[ -z "$ts" || "$ts" == "null" ]] && return
    local reset_epoch=""
    if [[ "$ts" =~ ^[0-9]+$ ]]; then
        reset_epoch="$ts"
    else
        local normalized=$(echo "$ts" | sed 's/\.[0-9]*//')
        local mac_ts=$(echo "$normalized" | sed 's/+00:00/+0000/; s/Z$/+0000/; s/+\([0-9][0-9]\):\([0-9][0-9]\)/+\1\2/')
        reset_epoch=$(date -d "$normalized" "+%s" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$mac_ts" "+%s" 2>/dev/null)
    fi
    [[ -z "$reset_epoch" ]] && return

    # GNU date (Windows/Linux) then macOS
    local hour=$(date -d "@$reset_epoch" "+%H" 2>/dev/null || date -j -f "%s" "$reset_epoch" "+%H" 2>/dev/null)
    local hour_12=$((10#$hour % 12))
    [[ $hour_12 -eq 0 ]] && hour_12=12
    local ampm="am"
    [[ $((10#$hour)) -ge 12 ]] && ampm="pm"

    local month_day=$(date -d "@$reset_epoch" "+%b %d" 2>/dev/null || date -j -f "%s" "$reset_epoch" "+%b %d" 2>/dev/null)
    echo "${month_day} at ${hour_12}${ampm}"
}

# Use rate_limits from stdin (provided by Claude Code) — no API call needed
FIVE_HOUR_RAW=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
SEVEN_DAY_RAW=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
FIVE_RESET_RAW=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
SEVEN_RESET_RAW=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Fallback to API call only if stdin doesn't have rate_limits
if [[ -z "$FIVE_HOUR_RAW" ]]; then
    USAGE_DATA=$(get_usage_data)
    if [[ -n "$USAGE_DATA" ]]; then
        FIVE_HOUR_RAW=$(echo "$USAGE_DATA" | jq -r '.five_hour.utilization // 0')
        FIVE_RESET_RAW=$(echo "$USAGE_DATA" | jq -r '.five_hour.resets_at // empty')
        SEVEN_DAY_RAW=$(echo "$USAGE_DATA" | jq -r '.seven_day.utilization // 0')
        SEVEN_RESET_RAW=$(echo "$USAGE_DATA" | jq -r '.seven_day.resets_at // empty')
    fi
fi

if [[ -n "$FIVE_HOUR_RAW" ]]; then
    FIVE_HOUR=$(printf "%.0f" "$FIVE_HOUR_RAW" 2>/dev/null || echo 0)
    FIVE_RESET="$FIVE_RESET_RAW"
    SEVEN_DAY=$(printf "%.0f" "$SEVEN_DAY_RAW" 2>/dev/null || echo 0)
    SEVEN_RESET="$SEVEN_RESET_RAW"

    FIVE_RESET_FMT=$(format_time_remaining "$FIVE_RESET")
    SEVEN_RESET_FMT=$(format_reset_datetime "$SEVEN_RESET")

    FIVE_BAR=$(generate_bar "$FIVE_HOUR" 40 "5h")
    SEVEN_BAR=$(generate_bar "$SEVEN_DAY" 40 "7d")

    FIVE_END_COLOR=$(get_usage_gradient_color "$FIVE_HOUR")
    SEVEN_END_COLOR=$(get_usage_7d_gradient_color "$SEVEN_DAY")

    LINE4="🚀 $(cat_lavender)5H Limit${RESET} ${FIVE_BAR} ${BOLD}\033[38;2;${FIVE_END_COLOR}m${FIVE_HOUR}%${RESET} (Resets ${FIVE_RESET_FMT})"
    LINE5="🌟 $(cat_yellow)7D Limit${RESET} ${SEVEN_BAR} ${BOLD}\033[38;2;${SEVEN_END_COLOR}m${SEVEN_DAY}%${RESET} (Resets ${SEVEN_RESET_FMT})"
else
    LINE4="🚀 $(cat_overlay)5H Limit${RESET}: N/A"
    LINE5="🌟 $(cat_overlay)7D Limit${RESET}: N/A"
fi

# ============================================================================
# Output
# ============================================================================
echo -e "$LINE1"
echo -e "$LINE2"
echo -e "$LINE3"
echo -e "$LINE4"
echo -e "$LINE5"
