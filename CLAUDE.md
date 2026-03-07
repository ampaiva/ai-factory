# AI Factory — Context for Claude

## O que é este projeto

Ambiente pessoal para rodar agentes de código autônomos overnight. O objetivo é criar uma "fábrica" que:

1. Lê issues do GitHub
2. Planeja implementações usando Claude
3. Escreve código
4. Roda testes
5. Abre Pull Requests automaticamente

## Estrutura

```
ai-factory/
├── CLAUDE.md
├── Makefile                  # Atalhos: start, stop, enter, logs
├── docker-compose.yml        # Container principal: ai-factory
├── docker/Dockerfile         # Imagem do container
├── .env / .env.example       # GITHUB_USER, ANTHROPIC_API_KEY, OPENAI_API_KEY, WORKSPACE
├── bootstrap.sh
├── config/
│   └── repos.yaml            # Lista de repositórios monitorados
├── orchestrator/
│   └── orchestrator.py       # Orquestrador: clona repos, faz pull, lista issues via gh CLI
├── agents/README.md
├── scripts/setup.sh
├── repos/                    # Repos clonados (gitkeep)
└── workspace/README.md
```

## Stack

- Python 3 (orquestrador)
- Docker / Docker Compose
- GitHub CLI (`gh`)
- Anthropic API (Claude)
- YAML para configuração de repos

## Repositórios monitorados (`config/repos.yaml`)

- `open-finance` — git@github.com:ampaiva/openfinance.git
- `bar-do-boy` — https://github.com/ampaiva/bar-do-boy

## Comandos úteis

```bash
make start   # docker compose up -d
make stop    # docker compose down
make enter   # docker exec -it ai-factory bash
make logs    # docker logs -f ai-factory
```

## Estado atual

O orquestrador (`orchestrator/orchestrator.py`) já:
- Lê `config/repos.yaml`
- Clona/atualiza os repos em `/repos/<name>`
- Lista issues via `gh issue list`

Ainda não implementado: planejamento com Claude, escrita de código, testes, abertura de PRs.

## Observações

- O container monta `./` em `/workspace`
- O projeto é voltado para rodar em Linux (Debian/Ubuntu), mas o dev atual está em macOS
