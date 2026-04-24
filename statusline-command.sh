#!/bin/bash

RESET=$'\e[0m'
DIM=$'\e[2m'
GRAY=$'\e[90m'
CYAN=$'\e[96m'
YELLOW=$'\e[93m'
GREEN=$'\e[92m'
BLUE=$'\e[94m'
RED=$'\e[91m'
ORANGE=$'\e[33m'

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

usage_pct=""
reset_time=""
progress_bar=""
api_mode=""

if [ -n "$ANTHROPIC_API_KEY" ]; then
  api_mode=1
fi

cache_file="$HOME/.claude/.statusline-usage-cache"
if [ -z "$api_mode" ] && [ -f "$cache_file" ]; then
  cache_ts=$(grep "^TIMESTAMP=" "$cache_file" 2>/dev/null | cut -d= -f2)
  now_ts=$(date +%s)
  if [ -n "$cache_ts" ]; then
    cache_age=$((now_ts - cache_ts))
    if [ "$cache_age" -lt 300 ]; then
      usage_pct=$(grep "^UTILIZATION=" "$cache_file" | cut -d= -f2)
      reset_epoch_str=$(grep "^RESETS_AT=" "$cache_file" | cut -d= -f2)
    fi
  fi
fi

if [ -z "$api_mode" ] && [ -z "$usage_pct" ]; then
  swift_result=$(swift "$HOME/.claude/fetch-claude-usage.swift" 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$swift_result" ]; then
    usage_pct=$(echo "$swift_result" | cut -d'|' -f1)
    reset_epoch_str=$(echo "$swift_result" | cut -d'|' -f2)
  fi
fi

usage_color="$GREEN"
if [ -n "$usage_pct" ] && [ "$usage_pct" != "~" ] && [ "$usage_pct" != "ERROR" ]; then
  if [ "$usage_pct" -ge 80 ]; then
    usage_color="$RED"
  elif [ "$usage_pct" -ge 50 ]; then
    usage_color="$ORANGE"
  fi
fi

if [ -n "$usage_pct" ] && [ "$usage_pct" != "ERROR" ]; then
  if [ "$usage_pct" -eq 0 ]; then
    filled_blocks=0
  elif [ "$usage_pct" -eq 100 ]; then
    filled_blocks=10
  else
    filled_blocks=$(( (usage_pct * 10 + 50) / 100 ))
  fi
  [ "$filled_blocks" -lt 0 ] && filled_blocks=0
  [ "$filled_blocks" -gt 10 ] && filled_blocks=10
  empty_blocks=$((10 - filled_blocks))

  filled_str=""
  i=0
  while [ $i -lt $filled_blocks ]; do
    filled_str="${filled_str}▓"
    i=$((i + 1))
  done
  empty_str=""
  i=0
  while [ $i -lt $empty_blocks ]; do
    empty_str="${empty_str}░"
    i=$((i + 1))
  done

  if [ -n "$reset_epoch_str" ] && [ "$reset_epoch_str" != "null" ]; then
    iso_time=$(echo "$reset_epoch_str" | sed 's/\.[0-9]*Z$//')
    reset_epoch=$(date -ju -f "%Y-%m-%dT%H:%M:%S" "$iso_time" "+%s" 2>/dev/null)
    if [ -n "$reset_epoch" ]; then
      now_epoch=$(date +%s)
      remaining=$((reset_epoch - now_epoch))
      if [ $remaining -gt 0 ] && [ $remaining -lt 18000 ]; then
        elapsed_secs=$((18000 - remaining))
        marker_pos=$(( (elapsed_secs * 10 + 9000) / 18000 ))
        [ $marker_pos -gt 9 ] && marker_pos=9
        [ $marker_pos -lt 0 ] && marker_pos=0
        filled_left="${filled_str:0:$marker_pos}"
        marker_char="┃"
        filled_right="${filled_str:$marker_pos}"
        filled_str="${filled_left}${marker_char}${filled_right:1}"
      fi

      seconds_part=$((reset_epoch % 60))
      if [ "$seconds_part" -ge 30 ]; then
        reset_epoch=$((reset_epoch + (60 - seconds_part)))
      else
        reset_epoch=$((reset_epoch - seconds_part))
      fi
      reset_time=$(date -r "$reset_epoch" "+%I:%M %p" 2>/dev/null)
    fi
  fi

  progress_bar=" ${usage_color}${filled_str}${GRAY}${empty_str}${RESET}"
else
  usage_pct="~"
fi

sep="${GRAY} │ ${RESET}"

line1="${CYAN}${model}${RESET}"
if [ -n "$api_mode" ]; then
  line1="${line1}${sep}${ORANGE}API billing${RESET}"
elif [ -n "$usage_pct" ]; then
  line1="${line1}${sep}${GRAY}Usage: ${usage_color}${usage_pct}%${RESET}${progress_bar}"
  if [ -n "$reset_time" ]; then
    line1="${line1}${GRAY} → Reset: ${CYAN}${reset_time}${RESET}"
  fi
fi

line2="${YELLOW}${current_dir}${RESET}"
if [ -n "$branch" ]; then
  line2="${line2}${GRAY} | ${GREEN}${branch}${RESET}"
else
  line2="${line2}${GRAY} | ${DIM}no git repo${RESET}"
fi
if [ -n "$ctx_pct" ]; then
  ctx_color="$GREEN"
  if [ "$ctx_pct" -ge 80 ]; then
    ctx_color="$RED"
  elif [ "$ctx_pct" -ge 50 ]; then
    ctx_color="$ORANGE"
  fi
  line2="${line2}${GRAY} | ctx ${ctx_color}${ctx_pct}%${RESET}"
fi

line3="${BLUE}${HOSTNAME}${RESET}${GRAY} | ${DIM}${session_id}${RESET}"

printf "%s\n" "$line1"
printf "%s\n" "$line2"
printf "%s\n" "$line3"
