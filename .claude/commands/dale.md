Crie um Pull Request para a branch atual seguindo o PR Workflow do CLAUDE.md e, se todos os checks passarem, faça o merge.

Passos:
1. Verifique a branch atual com `git branch --show-current`
   - Se for `main`: crie uma branch com nome descritivo baseado no contexto das alterações pendentes (`git checkout -b feature/nome`) e continue para o passo 2
   - Se não for `main`: continue direto para o passo 2
2. Verifique se a branch está vinculada a uma issue do GitHub:
   - Extraia o número da issue do nome da branch (ex: `feature/42-nome` → issue #42)
   - Se não encontrar número: verifique com `gh issue list --state open` se existe issue relevante pelo contexto das mudanças
   - Se não existir issue relacionada: crie uma com `gh issue create --assignee ampaiva` com título e body descritivos baseados nas alterações, e anote o número gerado
   - Aplique o label mais adequado à issue (nova ou existente) com `gh issue edit <número> --add-label "<label>"`, escolhendo entre: `bug`, `enhancement`, `documentation`, `question` — baseado no tipo de mudança
   - Use o número da issue no nome da branch se ainda estiver criando (ex: `feature/42-nome`) e nas referências do PR
3. Garanta que todos os testes passam
4. Commit das alterações pendentes com mensagem clara
5. Push para o remoto
6. Abra o PR com `gh pr create --assignee ampaiva` incluindo resumo do que foi feito e como testar, referenciando a issue com `Closes #<número>`
7. Aguarde os checks com `gh pr checks --watch`
8. Se todos os checks passarem, faça o merge com `gh pr merge --squash --delete-branch`
9. Se algum check falhar, reporte o erro e aguarde instrução
10. Após o merge:
    - `git checkout main && git pull` — volte para main atualizado
    - `git branch -d <branch-do-pr>` — delete o branch local
