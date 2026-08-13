#!/bin/sh
# One JSON object from the already-authenticated GitHub CLI.
# No tokens are stored by the plugin.

PATH="${HOME}/.local/share/mise/shims:${HOME}/.local/bin:/usr/bin:/bin:${PATH:-}"

if ! command -v gh >/dev/null 2>&1; then
  printf '%s\n' '{"ok":false,"error":"gh not found. Install GitHub CLI."}'
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  printf '%s\n' '{"ok":false,"error":"Run gh auth login."}'
  exit 0
fi

login=$(gh api user --jq '.login' 2>/dev/null) || login=""

notifs=$(gh api "notifications?per_page=50" --jq '{count:length, items:[.[:5][]|{title:.subject.title,type:.subject.type,repo:.repository.full_name,reason:.reason}]}' 2>/dev/null) \
  || notifs='{"count":0,"items":[]}'

# The notifications endpoint only returns the current page length, not the total.
# A second cheap call with per_page=1 still cannot total; use the search inbox for counts.
review=$(gh api "search/issues?q=is:open+is:pr+review-requested:@me&per_page=5" \
  --jq '{total:.total_count, items:[.items[]|{title:.title,url:.html_url,repo:.repository_url}]}' 2>/dev/null) \
  || review='{"total":0,"items":[]}'

mine=$(gh api "search/issues?q=is:open+is:pr+author:@me&per_page=5" \
  --jq '{total:.total_count, items:[.items[]|{title:.title,url:.html_url}]}' 2>/dev/null) \
  || mine='{"total":0,"items":[]}'

assigned=$(gh api "search/issues?q=is:open+assignee:@me&per_page=5" \
  --jq '{total:.total_count, items:[.items[]|{title:.title,url:.html_url}]}' 2>/dev/null) \
  || assigned='{"total":0,"items":[]}'

langs=$(gh api graphql -f query='query { viewer { repositories(first: 100, ownerAffiliations: OWNER, isFork: false, orderBy: {field: UPDATED_AT, direction: DESC}) { nodes { languages(first: 8, orderBy: {field: SIZE, direction: DESC}) { edges { size node { name } } } } } } }' \
  --jq '[.data.viewer.repositories.nodes[].languages.edges[]] | group_by(.node.name) | map({name:.[0].node.name, bytes:(map(.size)|add)}) | sort_by(-.bytes) | .[:15]' 2>/dev/null) \
  || langs='[]'

printf '{"ok":true,"login":"%s","notifications":%s,"reviews":%s,"prs":%s,"assigned":%s,"languages":%s}\n' \
  "$login" "$notifs" "$review" "$mine" "$assigned" "$langs"
