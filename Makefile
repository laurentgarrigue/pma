.PHONY: help init start stop clean create-networks

# Couleurs pour le terminal
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Fichiers et variables
ENV_FILE := .env
ENV_DIST := .env.dist
COMPOSE_DEV := compose.dev.yaml
COMPOSE_PROD := compose.prod.yaml

##@ Aide

help: ## Affiche cette aide
	@echo "$(BLUE)Makefile autodocumenté - phpMyAdmin$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Initialisation

init: ## Initialise le projet en créant le fichier .env de manière interactive
	@if [ -f $(ENV_FILE) ]; then \
		printf "$(YELLOW)⚠ Le fichier .env existe déjà.$(NC)\n"; \
		read -p "Voulez-vous le réinitialiser ? (y/N): " confirm; \
		if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
			printf "$(RED)Initialisation annulée.$(NC)\n"; \
			exit 1; \
		fi; \
		rm -f $(ENV_FILE); \
	fi; \
	printf "$(BLUE)🚀 Initialisation du projet phpMyAdmin$(NC)\n\n"; \
	cp $(ENV_DIST) $(ENV_FILE); \
	printf "$(GREEN)✓ Fichier .env créé à partir de .env.dist$(NC)\n\n"; \
	printf "$(BLUE)Configuration de l'environnement:$(NC)\n\n"; \
	while true; do \
		printf "$(YELLOW)Plateforme (dev/prod):$(NC) "; \
		read platform; \
		if [ "$$platform" = "dev" ] || [ "$$platform" = "prod" ]; then \
			sed -i "s/^PLATFORM=.*/PLATFORM=$$platform/" $(ENV_FILE); \
			break; \
		else \
			printf "$(RED)Veuillez entrer 'dev' ou 'prod'$(NC)\n"; \
		fi; \
	done; \
	printf "\n$(YELLOW)Nom de domaine (ex: example.com):$(NC) "; \
	read domain; \
	sed -i "s/^DOMAIN=.*/DOMAIN=$$domain/" $(ENV_FILE); \
	printf "\n$(YELLOW)Utilisateurs Traefik (format: user:hash,user2:hash2) [Entrée pour garder la valeur par défaut]:$(NC) "; \
	read traefik_users; \
	if [ -n "$$traefik_users" ]; then \
		escaped_users=$$(echo "$$traefik_users" | sed 's/\$$/\$\$$$/g'); \
		sed -i "s|^TRAEFIK_USERS=.*|TRAEFIK_USERS=$$escaped_users|" $(ENV_FILE); \
	fi; \
	printf "\n$(GREEN)✓ Configuration terminée !$(NC)\n\n"; \
	printf "$(BLUE)Fichier .env créé avec succès.$(NC)\n"; \
	printf "$(YELLOW)Vous pouvez maintenant lancer 'make start' pour démarrer le projet.$(NC)\n"

##@ Docker

create-networks: ## Crée les réseaux Docker s'ils n'existent pas
	@printf "$(BLUE)🔧 Vérification des réseaux Docker...$(NC)\n"
	@if ! docker network ls | grep -q pma_network; then \
		printf "$(YELLOW)Création du réseau pma_network...$(NC)\n"; \
		docker network create pma_network; \
		printf "$(GREEN)✓ Réseau pma_network créé$(NC)\n"; \
	else \
		printf "$(GREEN)✓ Réseau pma_network existe déjà$(NC)\n"; \
	fi
	@if ! docker network ls | grep -q traefiknetwork; then \
		printf "$(YELLOW)Création du réseau traefiknetwork...$(NC)\n"; \
		docker network create traefiknetwork; \
		printf "$(GREEN)✓ Réseau traefiknetwork créé$(NC)\n"; \
	else \
		printf "$(GREEN)✓ Réseau traefiknetwork existe déjà$(NC)\n"; \
	fi

start: create-networks ## Lance Docker Compose selon la plateforme configurée
	@if [ ! -f $(ENV_FILE) ]; then \
		printf "$(RED)❌ Le fichier .env n'existe pas !$(NC)\n"; \
		printf "$(YELLOW)Veuillez d'abord exécuter 'make init'$(NC)\n"; \
		exit 1; \
	fi; \
	. ./$(ENV_FILE) && \
	if [ "$$PLATFORM" = "dev" ]; then \
		printf "$(BLUE)🚀 Démarrage en mode DEV...$(NC)\n"; \
		docker compose -f $(COMPOSE_DEV) up -d; \
	elif [ "$$PLATFORM" = "prod" ]; then \
		printf "$(BLUE)🚀 Démarrage en mode PROD...$(NC)\n"; \
		docker compose -f $(COMPOSE_PROD) up -d; \
	else \
		printf "$(RED)❌ PLATFORM non définie ou invalide dans .env$(NC)\n"; \
		printf "$(YELLOW)Valeur trouvée: '$$PLATFORM'$(NC)\n"; \
		printf "$(YELLOW)Valeurs acceptées: 'dev' ou 'prod'$(NC)\n"; \
		exit 1; \
	fi; \
	printf "$(GREEN)✓ phpMyAdmin démarré avec succès !$(NC)\n"

stop: ## Arrête les conteneurs Docker
	@if [ ! -f $(ENV_FILE) ]; then \
		printf "$(RED)❌ Le fichier .env n'existe pas !$(NC)\n"; \
		exit 1; \
	fi; \
	. ./$(ENV_FILE) && \
	if [ "$$PLATFORM" = "dev" ]; then \
		printf "$(BLUE)🛑 Arrêt en mode DEV...$(NC)\n"; \
		docker compose -f $(COMPOSE_DEV) down; \
	elif [ "$$PLATFORM" = "prod" ]; then \
		printf "$(BLUE)🛑 Arrêt en mode PROD...$(NC)\n"; \
		docker compose -f $(COMPOSE_PROD) down; \
	else \
		printf "$(RED)❌ PLATFORM non définie dans .env$(NC)\n"; \
		exit 1; \
	fi; \
	printf "$(GREEN)✓ Conteneurs arrêtés$(NC)\n"

clean: stop ## Arrête et supprime les conteneurs, volumes et réseaux
	@printf "$(YELLOW)⚠ Nettoyage complet...$(NC)\n"
	@. ./$(ENV_FILE) && \
	if [ "$$PLATFORM" = "dev" ]; then \
		docker compose -f $(COMPOSE_DEV) down -v; \
	elif [ "$$PLATFORM" = "prod" ]; then \
		docker compose -f $(COMPOSE_PROD) down -v; \
	fi
	@printf "$(GREEN)✓ Nettoyage terminé$(NC)\n"

##@ Utilitaires

logs: ## Affiche les logs des conteneurs
	@if [ ! -f $(ENV_FILE) ]; then \
		printf "$(RED)❌ Le fichier .env n'existe pas !$(NC)\n"; \
		exit 1; \
	fi; \
	. ./$(ENV_FILE) && \
	if [ "$$PLATFORM" = "dev" ]; then \
		docker compose -f $(COMPOSE_DEV) logs -f; \
	elif [ "$$PLATFORM" = "prod" ]; then \
		docker compose -f $(COMPOSE_PROD) logs -f; \
	fi

status: ## Affiche le statut des conteneurs
	@if [ ! -f $(ENV_FILE) ]; then \
		printf "$(RED)❌ Le fichier .env n'existe pas !$(NC)\n"; \
		exit 1; \
	fi; \
	. ./$(ENV_FILE) && \
	if [ "$$PLATFORM" = "dev" ]; then \
		docker compose -f $(COMPOSE_DEV) ps; \
	elif [ "$$PLATFORM" = "prod" ]; then \
		docker compose -f $(COMPOSE_PROD) ps; \
	fi
