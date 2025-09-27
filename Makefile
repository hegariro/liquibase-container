# Makefile para gestión de migraciones con Liquibase
# Uso: make <comando> [ENV=ambiente] [TAG=version]

# Variables configurables
IMAGE_NAME ?= my-liquibase
IMAGE_TAG ?= latest
ENV_FILE ?= .env
CHANGELOG_DIR ?= ./changelog
DRIVERS_DIR ?= ./drivers

# Variables derivadas
FULL_IMAGE = $(IMAGE_NAME):$(IMAGE_TAG)
DOCKER_BASE_CMD = docker run --rm \
	--env-file $(ENV_FILE) \
	-v $(CHANGELOG_DIR):/liquibase/changelog \
	-v $(DRIVERS_DIR):/liquibase/drivers

# Colores para output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help build update status validate rollback rollback-count diff history clean logs shell

# Target por defecto
help: ## Mostrar esta ayuda
	@echo "$(GREEN)Liquibase Docker - Comandos disponibles:$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Ejemplos de uso:$(NC)"
	@echo "  make build                    # Construir imagen"
	@echo "  make update                   # Aplicar migraciones"
	@echo "  make rollback TAG=v1.0.0      # Rollback a tag específico"
	@echo "  make update ENV_FILE=.env.dev # Usar archivo de env específico"
	@echo ""
	@echo "$(YELLOW)Variables configurables:$(NC)"
	@echo "  IMAGE_NAME=$(IMAGE_NAME)"
	@echo "  IMAGE_TAG=$(IMAGE_TAG)"
	@echo "  ENV_FILE=$(ENV_FILE)"
	@echo "  CHANGELOG_DIR=$(CHANGELOG_DIR)"
	@echo "  DRIVERS_DIR=$(DRIVERS_DIR)"

build: ## Construir la imagen Docker de Liquibase
	@echo "$(GREEN)🏗️  Construyendo imagen $(FULL_IMAGE)...$(NC)"
	docker build -t $(FULL_IMAGE) .
	@echo "$(GREEN)✅ Imagen construida exitosamente$(NC)"

update: ## Aplicar todas las migraciones pendientes
	@echo "$(GREEN)🚀 Aplicando migraciones...$(NC)"
	$(DOCKER_BASE_CMD) $(FULL_IMAGE) update
	@echo "$(GREEN)✅ Migraciones aplicadas exitosamente$(NC)"

status: ## Verificar estado actual de migraciones
	@echo "$(YELLOW)📊 Verificando estado de migraciones...$(NC)"
	$(DOCKER_BASE_CMD) $(FULL_IMAGE) status

validate: ## Validar archivos de changelog
	@echo "$(YELLOW)🔍 Validando changelogs...$(NC)"
	$(DOCKER_BASE_CMD) $(FULL_IMAGE) validate
	@echo "$(GREEN)✅ Changelogs válidos$(NC)"

rollback: ## Rollback a un tag específico (usar: make rollback TAG=v1.0.0)
	@if [ -z "$(TAG)" ]; then \
		echo "$(RED)❌ Error: Debe especificar TAG. Ejemplo: make rollback TAG=v1.0.0$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)⏪ Ejecutando rollback a $(TAG)...$(NC)"
	$(DOCKER_BASE_CMD) $(FULL_IMAGE) rollback $(TAG)
	@echo "$(GREEN)✅ Rollback completado$(NC)"

rollback-count: ## Rollback de N changesets (usar: make rollback-count COUNT=5)
	@if [ -z "$(COUNT)" ]; then \
		echo "$(RED)❌ Error: Debe especificar COUNT. Ejemplo: make rollback-count COUNT=5$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)⏪ Ejecutando rollback de $(COUNT) changesets...$(NC)"
	$(DOCKER_BASE_CMD) $(FULL_IMAGE) rollback-count $(COUNT)
	@echo "$(GREEN)✅ Rollback completado$(NC)"

diff: ## Mostrar diferencias entre base de datos y changelog
	@echo "$(YELLOW)🔍 Mostrando diferencias...$(NC)"
	$(DOCKER_BASE_CMD) $(FULL_IMAGE) diff

history: ## Mostrar historial de migraciones ejecutadas
	@echo "$(YELLOW)📜 Historial de migraciones:$(NC)"
	$(DOCKER_BASE_CMD) $(FULL_IMAGE) history

changelog-sync: ## Marcar changesets como ejecutados sin aplicarlos
	@echo "$(YELLOW)🔄 Sincronizando changelog...$(NC)"
	$(DOCKER_BASE_CMD) $(FULL_IMAGE) changelog-sync
	@echo "$(GREEN)✅ Changelog sincronizado$(NC)"

generate-changelog: ## Generar changelog desde base de datos existente
	@echo "$(YELLOW)📝 Generando changelog desde BD...$(NC)"
	$(DOCKER_BASE_CMD) $(FULL_IMAGE) generate-changelog

# Comandos de utilidad
shell: ## Abrir shell interactivo en el contenedor
	@echo "$(GREEN)🐚 Abriendo shell en contenedor Liquibase...$(NC)"
	docker run --rm -it \
		--env-file $(ENV_FILE) \
		-v $(CHANGELOG_DIR):/liquibase/changelog \
		-v $(DRIVERS_DIR):/liquibase/drivers \
		$(FULL_IMAGE) bash

logs: ## Ver logs del último contenedor ejecutado
	@echo "$(YELLOW)📝 Logs del contenedor:$(NC)"
	docker logs $$(docker ps -lq)

clean: ## Limpiar imágenes no utilizadas
	@echo "$(GREEN)🧹 Limpiando imágenes no utilizadas...$(NC)"
	docker image prune -f
	@echo "$(GREEN)✅ Limpieza completada$(NC)"

clean-all: ## Limpiar todas las imágenes de Liquibase
	@echo "$(RED)🗑️  Eliminando todas las imágenes de $(IMAGE_NAME)...$(NC)"
	docker images $(IMAGE_NAME) -q | xargs -r docker rmi -f
	@echo "$(GREEN)✅ Imágenes eliminadas$(NC)"

# Comandos para diferentes ambientes
dev: ## Ejecutar update en ambiente de desarrollo
	@$(MAKE) update ENV_FILE=.env.dev

staging: ## Ejecutar update en ambiente de staging
	@$(MAKE) update ENV_FILE=.env.staging

prod: ## Ejecutar update en ambiente de producción (con confirmación)
	@echo "$(RED)⚠️  ADVERTENCIA: Ejecutarás migraciones en PRODUCCIÓN$(NC)"
	@echo "$(YELLOW)¿Estás seguro? [y/N]:$(NC)" && read ans && [ $${ans:-N} = y ]
	@$(MAKE) update ENV_FILE=.env.prod

# Comandos compuestos
deploy: build update ## Construir imagen y aplicar migraciones
	@echo "$(GREEN)🎉 Deploy completado$(NC)"

check: validate status ## Validar changelogs y mostrar estado
	@echo "$(GREEN)✅ Verificación completada$(NC)"

