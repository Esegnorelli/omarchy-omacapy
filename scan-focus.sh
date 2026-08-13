#!/bin/sh
# Print descendant process names of the focused Hyprland window.
# Used so a Ghostty title like "trabalho: ~" still reveals nvim / opencode / grok.

PATH="/usr/bin:/bin:/usr/local/bin:${PATH:-}"

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"
  if [ -d "$runtime" ]; then
    sig=$(ls -1 "$runtime" 2>/dev/null | head -1)
    [ -n "$sig" ] && HYPRLAND_INSTANCE_SIGNATURE=$sig
    export HYPRLAND_INSTANCE_SIGNATURE
  fi
fi

json=$(hyprctl activewindow -j 2>/dev/null) || exit 0
pid=$(printf '%s' "$json" | jq -r '.pid // empty' 2>/dev/null) || exit 0
[ -n "$pid" ] && [ "$pid" != "null" ] || exit 0

collect() {
  depth=$1
  p=$2
  [ "$depth" -gt 5 ] && return 0
  [ -r "/proc/$p/comm" ] || return 0
  tr -d '\n' < "/proc/$p/comm"
  printf ' '
  for c in $(pgrep -P "$p" 2>/dev/null); do
    collect $((depth + 1)) "$c"
  done
}

collect 0 "$pid"
printf '\n'
