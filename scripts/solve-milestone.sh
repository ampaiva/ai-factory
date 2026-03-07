#!/bin/bash
set -euo pipefail

# Usage:
#   ./solve-milestone.sh "milestone name"   # autonomous (used by orchestrator)
#   ./solve-milestone.sh                    # interactive (prompts for milestone)

if [ -n "${1:-}" ]; then
  MILESTONE="$1"
else
  MILESTONES=()
  while IFS= read -r line; do
    MILESTONES+=("$line")
  done < <(gh api repos/:owner/:repo/milestones --jq '.[] | select(.state=="open" and .open_issues > 0) | .title')

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

  MILESTONE="${MILESTONES[$((CHOICE-1))]}"
fi

echo ""
echo "Resolvendo issues do milestone: $MILESTONE"
echo ""

PREV_OPEN=-1

while true; do
  OPEN=$(gh issue list --milestone "$MILESTONE" --state open --json number --jq 'length')

  if [ "$OPEN" -eq 0 ]; then
    echo ""
    echo "✓ Todas as issues de '$MILESTONE' estão resolvidas!"
    break
  fi

  if [ "$OPEN" -eq "$PREV_OPEN" ]; then
    echo ""
    echo "✗ Nenhuma issue foi fechada na última sessão. Abortando para evitar loop infinito."
    exit 1
  fi

  PREV_OPEN=$OPEN

  ISSUE_NUMBER=$(gh issue list --milestone "$MILESTONE" --state open --json number --jq 'sort_by(.number) | .[0].number')
  echo "--- Issues abertas: $OPEN — resolvendo #$ISSUE_NUMBER do milestone '$MILESTONE' ---"
  echo ""

  TMPFILE=$(mktemp)

  set +e
  env -u CLAUDECODE claude --dangerously-skip-permissions -p "Resolva a issue #$ISSUE_NUMBER. Siga o workflow completo do comando /issue (ler a issue, implementar, criar PR e dar merge)." 2>&1 | tee "$TMPFILE"
  CLAUDE_EXIT=${PIPESTATUS[0]}
  set -e

  CLAUDE_OUTPUT=$(cat "$TMPFILE")
  rm -f "$TMPFILE"

  if [ $CLAUDE_EXIT -ne 0 ]; then
    if echo "$CLAUDE_OUTPUT" | grep -q "You've hit your limit"; then
      RESET_STR=$(echo "$CLAUDE_OUTPUT" | sed -n 's/.*resets \([0-9]*[ap]m\).*/\1/p' | head -1)

      if [ -z "$RESET_STR" ]; then
        echo ""
        echo "✗ Rate limit atingido mas não foi possível extrair o horário de reset. Abortando."
        exit 1
      fi

      RESET_HOUR_12=$(echo "$RESET_STR" | sed 's/[ap]m//')
      RESET_PERIOD=$(echo "$RESET_STR" | grep -o '[ap]m')

      if [ "$RESET_PERIOD" = "pm" ]; then
        if [ "$RESET_HOUR_12" -eq 12 ]; then
          RESET_HOUR_24=12
        else
          RESET_HOUR_24=$((RESET_HOUR_12 + 12))
        fi
      else
        if [ "$RESET_HOUR_12" -eq 12 ]; then
          RESET_HOUR_24=0
        else
          RESET_HOUR_24=$RESET_HOUR_12
        fi
      fi

      SP_HOUR=$(TZ=America/Sao_Paulo date +%H)
      SP_MIN=$(TZ=America/Sao_Paulo date +%M)
      SP_SEC=$(TZ=America/Sao_Paulo date +%S)

      ELAPSED=$(( 10#$SP_HOUR * 3600 + 10#$SP_MIN * 60 + 10#$SP_SEC ))
      TARGET=$(( RESET_HOUR_24 * 3600 ))

      if [ $ELAPSED -lt $TARGET ]; then
        WAIT=$((TARGET - ELAPSED + 60))
      else
        WAIT=$((86400 - ELAPSED + TARGET + 60))
      fi

      echo ""
      echo "Rate limit atingido. Reset às ${RESET_STR} SP. Aguardando $(( WAIT / 60 )) minutos..."
      sleep $WAIT
      PREV_OPEN=-1

    else
      echo ""
      echo "✗ Sessão Claude falhou (exit $CLAUDE_EXIT). Abortando."
      exit 1
    fi
  fi
done
