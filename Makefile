# =============================================================================
# AI Factory — Makefile
#
# HOST commands  : run from your machine (requires Docker)
# CONTAINER commands : run from inside the container (make enter first)
# =============================================================================

.PHONY: start stop restart build enter logs run orchestrate install help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-12s %s\n", $$1, $$2}'

# --- HOST commands ---

start: ## Start the container in background
	docker compose up -d

stop: ## Stop the container
	docker compose down

restart: stop build start ## Rebuild image and restart the container

build: ## Build the Docker image
	docker compose build

enter: ## Open a bash shell inside the container
	docker exec -it ai-factory bash

logs: ## Tail container logs
	docker logs -f ai-factory

run: ## Run the orchestrator from the host (via docker exec)
	docker exec ai-factory python /workspace/orchestrator/orchestrator.py

# --- CONTAINER commands (run these from inside the container) ---

orchestrate: ## Run the orchestrator
	python orchestrator/orchestrator.py

install: ## Install/update Python dependencies
	pip install -r requirements.txt