#!/bin/bash

config_file="$HOME/.claude/statusline-config.txt"
[ -f "$config_file" ] && source "$config_file"

SHOW_MODEL="${SHOW_MODEL:-1}"
SHOW_DIRECTORY="${SHOW_DIRECTORY:-1}"
SHOW_BRANCH="${SHOW_BRANCH:-1}"
SHOW_CONTEXT="${SHOW_CONTEXT:-1}"
SHOW_USAGE="${SHOW_USAGE:-1}"
SHOW_PROGRESS_BAR="${SHOW_PROGRESS_BAR:-1}"
SHOW_PACE_MARKER="${SHOW_PACE_MARKER:-1}"
SHOW_RESET_TIME="${SHOW_RESET_TIME:-1}"
USE_24_HOUR_TIME="${USE_24_HOUR_TIME:-0}"
SHOW_CONTEXT_LABEL="${SHOW_CONTEXT_LABEL:-1}"
SHOW_USAGE_LABEL="${SHOW_USAGE_LABEL:-1}"
SHOW_RESET_LABEL="${SHOW_RESET_LABEL:-1}"
COLOR_MODE="${COLOR_MODE:-colored}"

RESET=$'\e[0m'
DIM=$'\e[2m'
GRAY=$'\e[90m'
CYAN=$'\e[96m'
YELLOW=$'\e[93m'
GREEN=$'\e[92m'
BLUE=$'\e[94m'
RED=$'\e[91m'
ORANGE=$'\e[33m'

hex_color() {
  local hex="${1#\#}"
  [ ${#hex} -eq 6 ] || return
  printf '\e[38;2;%d;%d;%dm' $((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))
}

# Parse ISO8601 timestamp to epoch — tries macOS form first, falls back to Linux
iso_to_epoch() {
  local iso="$1" epoch
  epoch=$(date -ju -f "%Y-%m-%dT%H:%M:%S" "$iso" "+%s" 2>/dev/null)
  [ -z "$epoch" ] && epoch=$(date -d "$iso" "+%s" 2>/dev/null)
  printf '%s' "$epoch"
}

# Format epoch as time string — tries macOS -r, falls back to Linux -d @
epoch_to_time() {
  local epoch="$1" fmt="$2" t
  t=$(date -r "$epoch" "$fmt" 2>/dev/null)
  [ -z "$t" ] && t=$(date -d "@$epoch" "$fmt" 2>/dev/null)
  printf '%s' "$t"
}

if [ "$COLOR_MODE" = "single" ] && [ -n "$SINGLE_COLOR" ]; then
  _sc=$(hex_color "$SINGLE_COLOR")
  C_MODEL="$_sc" C_DIR="$_sc" C_BRANCH="$_sc" C_CTX="$_sc" C_SEP="$_sc"
else
  C_MODEL="${ELEMENT_COLOR_MODEL:+$(hex_color "$ELEMENT_COLOR_MODEL")}"; C_MODEL="${C_MODEL:-$CYAN}"
  C_DIR="${ELEMENT_COLOR_DIR:+$(hex_color "$ELEMENT_COLOR_DIR")}"; C_DIR="${C_DIR:-$YELLOW}"
  C_BRANCH="${ELEMENT_COLOR_BRANCH:+$(hex_color "$ELEMENT_COLOR_BRANCH")}"; C_BRANCH="${C_BRANCH:-$GREEN}"
  C_CTX="${ELEMENT_COLOR_CONTEXT:+$(hex_color "$ELEMENT_COLOR_CONTEXT")}"
  C_SEP="${ELEMENT_COLOR_SEPARATOR:+$(hex_color "$ELEMENT_COLOR_SEPARATOR")}"; C_SEP="${C_SEP:-$GRAY}"
fi

input=$(cat)

model=$(echo "$input" | grep -o '"display_name":"[^"]*"' | sed 's/"display_name":"//;s/"$//')
current_dir_path=$(echo "$input" | grep -o '"current_dir":"[^"]*"' | sed 's/"current_dir":"//;s/"$//')
current_dir=$(basename "$current_dir_path")
session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | sed 's/"session_id":"//;s/"$//')
ctx_pct=$(echo "$input" | grep -o '"used_percentage":[0-9.]*' | head -1 | sed 's/"used_percentage"://' | cut -d. -f1)

branch=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null)
fi

usage_pct="" reset_time="" progress_bar="" api_mode="" reset_epoch="" reset_epoch_str=""

[ -n "$ANTHROPIC_API_KEY" ] && api_mode=1

cache_file="$HOME/.claude/.statusline-usage-cache"
if [ -z "$api_mode" ] && [ -f "$cache_file" ]; then
  cache_ts=$(grep "^TIMESTAMP=" "$cache_file" 2>/dev/null | cut -d= -f2)
  now_ts=$(date +%s)
  if [ -n "$cache_ts" ] && [ $(( now_ts - cache_ts )) -lt 300 ]; then
    usage_pct=$(grep "^UTILIZATION=" "$cache_file" | cut -d= -f2)
    reset_epoch_str=$(grep "^RESETS_AT=" "$cache_file" | cut -d= -f2)
  fi
fi

if [ -z "$api_mode" ] && [ -z "$usage_pct" ]; then
  swift_result=$(swift "$HOME/.claude/fetch-claude-usage.swift" 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$swift_result" ]; then
    usage_pct=$(echo "$swift_result" | cut -d'|' -f1)
    reset_epoch_str=$(echo "$swift_result" | cut -d'|' -f2)
  fi
fi

if [ -n "$usage_pct" ] && [ "$usage_pct" != "ERROR" ]; then
  usage_color="$GREEN"
  if [ "$usage_pct" -ge 80 ] 2>/dev/null; then usage_color="$RED"
  elif [ "$usage_pct" -ge 50 ] 2>/dev/null; then usage_color="$ORANGE"; fi

  if [ -n "$reset_epoch_str" ] && [ "$reset_epoch_str" != "null" ]; then
    iso_time=$(echo "$reset_epoch_str" | sed 's/\.[0-9]*Z$//')
    reset_epoch=$(iso_to_epoch "$iso_time")
  fi

  if [ "$SHOW_PROGRESS_BAR" = "1" ]; then
    if [ "$usage_pct" -eq 0 ] 2>/dev/null; then filled_blocks=0
    elif [ "$usage_pct" -eq 100 ] 2>/dev/null; then filled_blocks=10
    else filled_blocks=$(( (usage_pct * 10 + 50) / 100 )); fi
    [ "$filled_blocks" -lt 0 ] && filled_blocks=0
    [ "$filled_blocks" -gt 10 ] && filled_blocks=10
    empty_blocks=$((10 - filled_blocks))

    filled_str="" i=0
    while [ $i -lt $filled_blocks ]; do filled_str="${filled_str}▓"; i=$((i+1)); done
    empty_str="" i=0
    while [ $i -lt $empty_blocks ]; do empty_str="${empty_str}░"; i=$((i+1)); done

    if [ "$SHOW_PACE_MARKER" = "1" ] && [ -n "$reset_epoch" ]; then
      now_epoch=$(date +%s)
      remaining=$((reset_epoch - now_epoch))
      if [ $remaining -gt 0 ] && [ $remaining -lt 18000 ]; then
        elapsed_secs=$((18000 - remaining))
        marker_pos=$(( (elapsed_secs * 10 + 9000) / 18000 ))
        [ $marker_pos -gt 9 ] && marker_pos=9
        [ $marker_pos -lt 0 ] && marker_pos=0
        filled_left="${filled_str:0:$marker_pos}"
        filled_right="${filled_str:$marker_pos}"
        filled_str="${filled_left}┃${filled_right:1}"
      fi
    fi

    progress_bar=" ${usage_color}${filled_str}${C_SEP}${empty_str}${RESET}"
  fi

  if [ "$SHOW_RESET_TIME" = "1" ] && [ -n "$reset_epoch" ]; then
    seconds_part=$((reset_epoch % 60))
    [ "$seconds_part" -ge 30 ] \
      && reset_epoch=$((reset_epoch + 60 - seconds_part)) \
      || reset_epoch=$((reset_epoch - seconds_part))
    if [ "$USE_24_HOUR_TIME" = "1" ]; then
      reset_time=$(epoch_to_time "$reset_epoch" "+%H:%M")
    else
      reset_time=$(epoch_to_time "$reset_epoch" "+%I:%M %p")
    fi
  fi
else
  usage_pct="~"
fi

sep="${C_SEP} │ ${RESET}"

line1=""
[ "$SHOW_MODEL" = "1" ] && line1="${C_MODEL}${model}${RESET}"

if [ -n "$api_mode" ]; then
  [ -n "$line1" ] && line1="${line1}${sep}"
  line1="${line1}${ORANGE}API billing${RESET}"
elif [ "$SHOW_USAGE" = "1" ] && [ -n "$usage_pct" ]; then
  label=""; [ "$SHOW_USAGE_LABEL" = "1" ] && label="Usage: "
  [ -n "$line1" ] && line1="${line1}${sep}"
  line1="${line1}${C_SEP}${label}${usage_color}${usage_pct}%${RESET}${progress_bar}"
  if [ -n "$reset_time" ]; then
    reset_label=""; [ "$SHOW_RESET_LABEL" = "1" ] && reset_label=" → Reset: "
    line1="${line1}${C_SEP}${reset_label}${CYAN}${reset_time}${RESET}"
  fi
fi

line2=""
if [ "$SHOW_DIRECTORY" = "1" ]; then
  line2="${C_DIR}${current_dir}${RESET}"
fi
if [ "$SHOW_BRANCH" = "1" ]; then
  [ -n "$line2" ] && line2="${line2}${C_SEP} | ${RESET}"
  if [ -n "$branch" ]; then
    line2="${line2}${C_BRANCH}${branch}${RESET}"
  else
    line2="${line2}${DIM}no git repo${RESET}"
  fi
fi
if [ "$SHOW_CONTEXT" = "1" ] && [ -n "$ctx_pct" ]; then
  ctx_color="${C_CTX}"
  if [ -z "$ctx_color" ]; then
    ctx_color="$GREEN"
    if [ "$ctx_pct" -ge 80 ] 2>/dev/null; then ctx_color="$RED"
    elif [ "$ctx_pct" -ge 50 ] 2>/dev/null; then ctx_color="$ORANGE"; fi
  fi
  label=""; [ "$SHOW_CONTEXT_LABEL" = "1" ] && label="ctx "
  [ -n "$line2" ] && line2="${line2}${C_SEP} | ${RESET}"
  line2="${line2}${ctx_color}${label}${ctx_pct}%${RESET}"
fi

line3="${BLUE}${HOSTNAME}${RESET}${C_SEP} | ${DIM}${session_id}${RESET}"

printf "%s\n" "$line1"
printf "%s\n" "$line2"
printf "%s\n" "$line3"
