# phpMyAdmin avec Docker & Traefik

Déploiement de phpMyAdmin avec Docker Compose et reverse proxy Traefik, compatible dev et production.

## Prérequis

- Docker et Docker Compose
- Make

## Démarrage rapide

```bash
# 1. Initialiser le projet (crée le fichier .env)
make init

# 2. Démarrer les conteneurs
make start

# 3. Accéder à phpMyAdmin
# Dev: http://localhost ou http://votre-domaine.local
# Prod: https://votre-domaine.com
```

## Commandes disponibles

```bash
make help          # Afficher l'aide complète
make init          # Initialiser la configuration
make start         # Démarrer les conteneurs
make stop          # Arrêter les conteneurs
make clean         # Nettoyage complet (conteneurs + volumes)
make logs          # Afficher les logs
make status        # Statut des conteneurs
```

## Configuration

La commande `make init` configure interactivement :
- **Plateforme** : `dev` ou `prod`
- **Domaine** : nom de domaine pour accéder à l'interface
- **Utilisateurs Traefik** : authentification HTTP (format `user:hash`)

Le fichier `.env` est créé automatiquement à partir de `.env.dist`.

## Architectures disponibles

- **Dev** (`compose.dev.yaml`) : configuration locale sans SSL
- **Prod** (`compose.prod.yaml`) : avec Let's Encrypt et HTTPS

## Réseaux Docker

Deux réseaux sont créés automatiquement :
- `pma_network` : réseau interne phpMyAdmin
- `traefiknetwork` : réseau Traefik pour le reverse proxy
