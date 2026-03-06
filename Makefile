start:
	docker compose up -d

stop:
	docker compose down

enter:
	docker exec -it ai-factory bash

logs:
	docker logs -f ai-factory