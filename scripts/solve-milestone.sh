#!/bin/bash
set -euo pipefail

# Usage:
#   ./solve-milestone.sh "milestone name"
#   ./solve-milestone.sh

get_reset_wait_time() {

  CLAUDE_OUTPUT="$1"

  RESET_FULL=$(echo "$CLAUDE_OUTPUT" | sed -n 's/.*resets \(.*\)).*/\1)/p' | head -1)
  echo "Reset detectado: $RESET_FULL"

  if [ -z "$RESET_FULL" ]; then
    echo "ERROR"
    return
  fi

  # separa timezone
  TIMEZONE=$(echo "$RESET_FULL" | sed -n 's/.*(\(.*\)).*/\1/p')
  DATE_PART=$(echo "$RESET_FULL" | sed 's/ (.*)//')

  # se não tiver mês/dia → assume hoje
  if [[ ! "$DATE_PART" =~ [A-Za-z]{3} ]]; then
    TODAY=$(TZ="$TIMEZONE" date "+%b %d")
    DATE_PART="$TODAY, $DATE_PART"
  fi

  TARGET=$(TZ="$TIMEZONE" date -d "$DATE_PART" +%s)
  NOW=$(date +%s)

  WAIT=$((TARGET - NOW + 60))

  if [ "$WAIT" -lt 0 ]; then
    WAIT=60
  fi

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
    echo "⚠ Issue não foi fechada."
  fi

  echo ""

  INDEX=$((INDEX+1))

done