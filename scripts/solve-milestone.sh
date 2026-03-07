#!/bin/bash
set -euo pipefail

# Usage:
#   ./solve-milestone.sh "milestone name"
#   ./solve-milestone.sh

get_reset_wait_time() {

  CLAUDE_OUTPUT="$1"

  RESET_FULL=$(echo "$CLAUDE_OUTPUT" | grep -oE 'resets .*' | sed 's/resets //' | head -1)

  if [ -z "${RESET_FULL:-}" ]; then
    echo "ERROR"
    return
  fi

  echo "Reset detectado: $RESET_FULL" >&2

  TZ=$(echo "$RESET_FULL" | sed -n 's/.*(\(.*\)).*/\1/p')
  PART=$(echo "$RESET_FULL" | sed 's/ (.*)//')

  MONTH=$(echo "$PART" | awk '{print $1}')
  DAY=$(echo "$PART" | awk '{print $2}' | tr -d ',')

  TIME=$(echo "$PART" | grep -oE '[0-9]{1,2}[ap]m')

  HOUR=$(echo "$TIME" | sed 's/[ap]m//')
  AMPM=$(echo "$TIME" | grep -oE '[ap]m')

  if [ "$AMPM" = "pm" ] && [ "$HOUR" -lt 12 ]; then
    HOUR=$((HOUR+12))
  fi

  if [ "$AMPM" = "am" ] && [ "$HOUR" -eq 12 ]; then
    HOUR=0
  fi

  case "$MONTH" in
    Jan) M=01 ;;
    Feb) M=02 ;;
    Mar) M=03 ;;
    Apr) M=04 ;;
    May) M=05 ;;
    Jun) M=06 ;;
    Jul) M=07 ;;
    Aug) M=08 ;;
    Sep) M=09 ;;
    Oct) M=10 ;;
    Nov) M=11 ;;
    Dec) M=12 ;;
    *) echo "ERROR"; return ;;
  esac

  YEAR=$(date +%Y)

  TARGET=$(date -d "$YEAR-$M-$DAY $HOUR:00:00 $TZ" +%s 2>/dev/null)

  if [ -z "${TARGET:-}" ]; then
    echo "ERROR"
    return
  fi

  NOW=$(date +%s)

  WAIT=$((TARGET - NOW + 60))

  echo "$WAIT"
}

choose_milestone() {

  mapfile -t MILESTONES < <(
    gh api repos/:owner/:repo/milestones \
    --jq '.[] | select(.state=="open" and .open_issues > 0) | .title'
  )

  if [ ${#MILESTONES[@]} -eq 0 ]; then
    echo "Nenhum milestone aberto encontrado."
    exit 1
  fi

  echo "Milestones abertos:"
  for i in "${!MILESTONES[@]}"; do
    echo "  $((i+1))) ${MILESTONES[$i]}"
  done
  echo ""

  read -rp "Escolha o milestone (1-${#MILESTONES[@]}): " CHOICE

  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#MILESTONES[@]}" ]; then
    echo "Escolha inválida."
    exit 1
  fi

  echo "${MILESTONES[$((CHOICE-1))]}"
}

fetch_open_issues() {

  gh issue list \
    --milestone "$1" \
    --state open \
    --limit 500 \
    --json number \
    --jq 'sort_by(.number) | .[].number'
}

try_merge_issue_pr() {

  ISSUE="$1"

  PR_NUMBER=$(gh pr list \
    --state open \
    --search "$ISSUE" \
    --json number \
    --jq '.[0].number' 2>/dev/null || true)

  if [ -z "${PR_NUMBER:-}" ]; then
    echo "Nenhum PR encontrado para issue #$ISSUE"
    return
  fi

  echo "PR encontrado: #$PR_NUMBER"

  if gh pr merge "$PR_NUMBER" --squash --auto --delete-branch 2>/dev/null; then
    echo "Merge automático configurado."
    return
  fi

  if gh pr merge "$PR_NUMBER" --squash --delete-branch 2>/dev/null; then
    echo "Merge realizado."
    return
  fi

  echo "Não foi possível fazer merge do PR #$PR_NUMBER"
}

echo ""

if [ -n "${1:-}" ]; then
  MILESTONE="$1"
else
  MILESTONE=$(choose_milestone)
fi

echo "Resolvendo issues do milestone: $MILESTONE"
echo ""

mapfile -t ISSUES < <(fetch_open_issues "$MILESTONE")

if [ ${#ISSUES[@]} -eq 0 ]; then
  echo "Nenhuma issue aberta."
  exit 0
fi

INDEX=0
TOTAL=${#ISSUES[@]}
PREV_OPEN=$TOTAL

while true; do

  if [ $INDEX -ge $TOTAL ]; then

    echo ""
    echo "Rechecando issues abertas..."

    mapfile -t ISSUES < <(fetch_open_issues "$MILESTONE")

    OPEN=${#ISSUES[@]}

    if [ "$OPEN" -eq 0 ]; then
      echo ""
      echo "✓ Todas as issues de '$MILESTONE' estão resolvidas!"
      exit 0
    fi

    if [ "$OPEN" -eq "$PREV_OPEN" ]; then
      echo ""
      echo "✗ Nenhuma issue foi fechada na última sessão. Abortando."
      exit 1
    fi

    PREV_OPEN=$OPEN
    TOTAL=$OPEN
    INDEX=0

    continue
  fi

  ISSUE_NUMBER="${ISSUES[$INDEX]}"

  echo "---------------------------------------"
  echo "Issue $((INDEX+1)) de $TOTAL → #$ISSUE_NUMBER"
  echo "---------------------------------------"
  echo ""

  TMPFILE=$(mktemp)

  set +e
  env -u CLAUDECODE claude \
    --dangerously-skip-permissions \
    -p "Resolva a issue #$ISSUE_NUMBER. Siga o workflow completo do comando /issue (ler a issue, implementar, criar PR e dar merge)." \
    2>&1 | tee "$TMPFILE"

  CLAUDE_EXIT=${PIPESTATUS[0]}
  set -e

  CLAUDE_OUTPUT=$(cat "$TMPFILE")
  rm -f "$TMPFILE"

  if [ $CLAUDE_EXIT -ne 0 ]; then

    if echo "$CLAUDE_OUTPUT" | grep -q "Not logged in"; then
      echo ""
      echo "Claude não está logado. Abortando execução."
      exit 1
    fi

    if echo "$CLAUDE_OUTPUT" | grep -q "You've hit your limit"; then

      echo ""
      echo "Rate limit detectado."

      WAIT=$(get_reset_wait_time "$CLAUDE_OUTPUT")

      if [ "$WAIT" = "ERROR" ]; then
        echo "Não foi possível extrair horário de reset."
        exit 1
      fi

      echo "Aguardando $((WAIT/60)) minutos..."
      echo ""

      sleep "$WAIT"

      continue
    fi

    echo ""
    echo "Claude falhou (exit $CLAUDE_EXIT). Pulando issue."
    echo ""

    INDEX=$((INDEX+1))
    continue
  fi

  echo ""
  echo "Verificando se issue foi fechada..."

  STATE=$(gh issue view "$ISSUE_NUMBER" --json state --jq '.state')

  if [ "$STATE" = "CLOSED" ]; then

    echo "✓ Issue #$ISSUE_NUMBER fechada."

  else

    echo "Issue ainda aberta. Procurando PR..."

    try_merge_issue_pr "$ISSUE_NUMBER"

    sleep 3

    STATE=$(gh issue view "$ISSUE_NUMBER" --json state --jq '.state')

    if [ "$STATE" = "CLOSED" ]; then
      echo "✓ Issue fechada após merge."
    else
      echo "⚠ Issue ainda aberta."
    fi

fi

  echo ""

  INDEX=$((INDEX+1))

done