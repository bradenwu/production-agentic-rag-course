.PHONY: help start start-docker-ollama stop restart status logs health setup format lint test test-cov clean

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Service management
start: ## Start services (auto-detects host Ollama, falls back to Docker Ollama)
	@if curl -sf http://localhost:11434/api/version > /dev/null 2>&1; then \
		echo "✓ Host Ollama detected - using http://host.docker.internal:11434"; \
		OLLAMA_HOST=http://host.docker.internal:11434 docker compose up --build -d; \
	else \
		echo "Host Ollama not found - starting Docker Ollama container"; \
		OLLAMA_HOST=http://ollama:11434 docker compose --profile docker-ollama up --build -d; \
	fi

start-docker-ollama: ## Force start with Docker Ollama (ignores host Ollama)
	OLLAMA_HOST=http://ollama:11434 docker compose --profile docker-ollama up --build -d

stop: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

status: ## Show service status
	docker compose ps

logs: ## Show service logs
	docker compose logs -f

# Health checks
health: ## Check all services health
	@echo "Checking service health..."
	@curl -s http://localhost:8000/health | jq . || echo "API not responding"
	@curl -s http://localhost:9200/_cluster/health | jq . || echo "OpenSearch not responding"
	@curl -s http://localhost:8080/api/v2/monitor/health || echo "Airflow not responding"
	@curl -s http://localhost:11434/api/version | jq . || echo "Ollama not responding"

# Development
setup: ## Install Python dependencies
	uv sync

format: ## Format code
	uv run ruff format

lint: ## Lint and type check
	uv run ruff check --fix
	uv run mypy src/

test: ## Run tests
	uv run pytest

test-cov: ## Run tests with coverage
	uv run pytest --cov=src --cov-report=html

# Cleanup
clean: ## Clean up everything
	docker compose down -v
	docker system prune -f