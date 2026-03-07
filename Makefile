# --- Host commands ---

start:
	docker compose up -d

stop:
	docker compose down

restart: stop build start

build:
	docker compose build

enter:
	docker exec -it ai-factory bash

logs:
	docker logs -f ai-factory

# Run orchestrator from host (via docker exec)
run:
	docker exec ai-factory python /workspace/orchestrator/orchestrator.py

# --- Container commands (run these from inside the container) ---

# python orchestrator/orchestrator.py
orchestrate:
	python orchestrator/orchestrator.py

# Install/update Python dependencies
install:
	pip install -r requirements.txt