Resolva a próxima issue aberta no GitHub — aquela com o menor número de ID.

## Início

1. Identifique a issue: `gh issue list --state open --json number,title,body --limit 50 | jq 'sort_by(.number) | .[0]'`
2. `git checkout main && git pull` — sempre parta de um main atualizado
3. Atribua a issue a `ampaiva` e mova para **In Progress** no projeto:
   ```bash
   gh issue edit <number> --add-assignee ampaiva
   ```
4. Crie e suba a branch antes de escrever qualquer código: `git checkout -b feature/name && git push -u origin feature/name`
5. Leia o `CLAUDE.md` e a descrição da issue antes de tocar no código

## Implementação

6. Implemente a solução seguindo os padrões do projeto

## Finalização (PR Workflow)

7. Faça commits com mensagens claras
8. Ao terminar, execute o comando `dale`
