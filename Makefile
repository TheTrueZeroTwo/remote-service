.PHONY: test validate build up down logs clean

test:
	./scripts/test-verbose.sh

validate:
	python3 scripts/validate.py

build:
	docker build --progress=plain -t lnreader-remote-service:local .

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f --tail=200

clean:
	rm -rf .pytest_cache .venv __pycache__ tests/__pycache__ scripts/__pycache__ src/__pycache__ src/server/__pycache__
