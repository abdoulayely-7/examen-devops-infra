# Configuration & Orchestration — Ansible

Ce répertoire contient l'ensemble des playbooks et rôles **Ansible** conçus selon une architecture modulaire, professionnelle et **100% idempotente** pour préparer, sécuriser et déployer la stack de production sur l'instance AWS EC2.

---

## 1. Vue d'ensemble de l'Architecture Ansible

```text
ansible/
├── inventory/
│   └── production.ini            # Inventaire généré automatiquement par Terraform
├── site.yml                      # Playbook maître orchestrant tous les rôles
└── roles/
    ├── common/                   # Préparation OS, 4 Go Swap, paramètres noyau sysctl
    ├── docker/                   # Installation Docker Engine CE 29+, Compose & réseaux
    ├── traefik/                  # Configuration reverse-proxy, ACME Let's Encrypt HTTPS
    ├── prometheus/               # Configuration Prometheus & règles de scraping
    ├── node-exporter/            # Métriques système hôte (CPU, RAM, Disque, Réseau)
    ├── cadvisor/                 # Métriques conteneurs Docker (cgroup, ressources)
    ├── grafana/                  # Provisioning datasources & dashboards (EC2, Docker, App)
    ├── sonarqube/                # Prérequis noyau Linux pour SonarQube & volumes
    └── app/                      # Déploiement unifié Docker Compose & variables d'environnement
```

---

## 2. Dépendances et interactions avec les autres dossiers

1. **Dépendance envers `terraform/` (Amont)** :
   - Ansible dépend directement du fichier d'inventaire [`inventory/production.ini`](./inventory/production.ini) généré par Terraform.
   - Il utilise la clé privée SSH générée par Terraform dans `~/.ssh/devops-prod-key`.
2. **Dépendance envers `.github/workflows/` (Aval)** :
   - Ansible configure le répertoire `/opt/myapp/` sur le serveur EC2 avec le fichier [`docker-compose.yml`](./roles/app/files/docker-compose.yml) et le fichier `.env`.
   - Le pipeline GitHub Actions CD (`deploy.yml`) se connecte en SSH sur ce même serveur pour mettre à jour la variable `APP_TAG` et redémarrer le conteneur `application`.
3. **Dépendance envers Neon PostgreSQL & Docker Hub** :
   - Les identifiants de la base de données Neon PostgreSQL sont injectés dans `/opt/myapp/.env` par le rôle `app`.
   - L'image applicative déployée provient du Docker Hub (`abdoulayely777/examen-devops-back`).

---

## 3. Détail des Rôles Ansible

### 1. Rôle `common`
- **Objectif** : Fiabiliser l'OS Ubuntu 24.04 pour supporter une stack complète sur une instance `t3.small` (2 Go RAM).
- **Actions** :
  - Création et activation d'un fichier **Swap de 4 Go** (`/swapfile`) avec `swappiness=10`.
  - Configuration des paramètres noyau pour SonarQube et Docker :
    - `vm.max_map_count = 262144` (indispensable pour le moteur Elasticsearch interne de SonarQube).
    - `fs.file-max = 65536` (limite du nombre de descripteurs de fichiers).

### 2. Rôle `docker`
- **Objectif** : Installer la dernière version stable de Docker CE et du plugin Docker Compose.
- **Actions** :
  - Ajout du dépôt officiel Docker Ubuntu et de la clé GPG.
  - Installation de `docker-ce`, `docker-ce-cli`, `containerd.io`, et `docker-compose-plugin`.
  - Ajout de l'utilisateur `ubuntu` au groupe `docker` (évite l'usage systématique de `sudo`).
  - Création des deux réseaux Docker bridge isolés :
    - **`traefik-public`** : Réseau d'exposition externe (Traefik ↔ Services web).
    - **`internal`** : Réseau de collecte interne sécurisé (Prometheus ↔ Exporters).

### 3. Rôle `traefik`
- **Objectif** : Mettre en place le point d'entrée unique HTTP/HTTPS.
- **Actions** :
  - Préparation du dossier `/opt/myapp/traefik/acme/` avec les permissions strictes `0600` pour le stockage sécurisé des certificats Let's Encrypt (`acme.json`).
  - Configuration du challenge HTTP Let's Encrypt et de la redirection automatique permanente (`HTTP 308 Permanent Redirect`) du port 80 vers le port 443.

### 4. Rôles de Monitoring (`prometheus`, `node-exporter`, `cadvisor`)
- **`prometheus`** : Déploie la configuration [`prometheus.yml`](./roles/prometheus/files/prometheus.yml) configurée pour scraper toutes les 15 secondes :
  - `application` (`http://examen-devops-back:8080/actuator/prometheus`)
  - `cadvisor` (`http://cadvisor:8080/metrics`)
  - `node-exporter` (`http://node-exporter:9100/metrics`)
  - `prometheus` (`http://localhost:9090/metrics`)
- **`node-exporter`** : Collecteur des métriques matérielles avec montage en lecture seule des chemins hôte (`/proc`, `/sys`).
- **`cadvisor`** : Collecteur des métriques de conteneurs avec accès au socket Docker `/var/run/docker.sock` et aux `cgroups`.

### 5. Rôle `grafana`
- **Objectif** : Visualisation unifiée des métriques sans intervention manuelle (*Zero-Touch Dashboarding*).
- **Actions** :
  - **Datasource automatique** : Provisionne la source de données Prometheus pointant sur `http://prometheus:9090`.
  - **Dashboards pré-chargés** (3 tableaux de bord de niveau production) :
    1. `ec2-server-monitoring.json` : CPU hôte, RAM libre, Swap actif, trafic réseau et I/O disque.
    2. `docker-monitoring.json` : CPU et mémoire par conteneur, statut des conteneurs, redémarrages.
    3. `application-monitoring.json` : Débit de requêtes Spring Boot (RPS), latence p95/p99, mémoire JVM Heap, pool de connexions HikariCP Neon DB.

### 6. Rôle `sonarqube`
- **Objectif** : Hébergement de l'instance d'analyse statique du code et du Quality Gate.
- **Actions** :
  - Création des répertoires de données persistantes (`sonarqube_data`, `sonarqube_extensions`, `sonarqube_logs`) avec l'UID/GID propriétaire `1000:1000`.

### 7. Rôle `app`
- **Objectif** : Déploiement et exécution de la stack globale orchestrée.
- **Actions** :
  - Copie du fichier [`docker-compose.yml`](./roles/app/files/docker-compose.yml) maître dans `/opt/myapp/`.
  - Déploiement du fichier `/opt/myapp/.env` contenant les variables d'environnement et secrets Neon PostgreSQL.
  - Lancement coordonné des services via `docker compose up -d`.

---

## 4. Guide des commandes opérationnelles

### Prérequis
- Ansible (v2.14+) installé sur la machine d'administration (WSL Ubuntu).
- Clé SSH `~/.ssh/devops-prod-key` avec permissions `0600`.
- Inventaire [`inventory/production.ini`](./inventory/production.ini) présent et à jour.

### 1. Tester la connectivité (Ping SSH)
```bash
cd ansible
ansible -i inventory/production.ini prod-ec2 -m ping
```

### 2. Déployer l'ensemble de l'infrastructure
```bash
ansible-playbook -i inventory/production.ini site.yml
```

### 3. Exécuter un rôle ou composant spécifique (Tags)
```bash
# Uniquement le monitoring Grafana
ansible-playbook -i inventory/production.ini site.yml --tags "grafana"

# Uniquement la stack applicative
ansible-playbook -i inventory/production.ini site.yml --tags "app"
```

### 4. Vérification d'idempotence
Une seconde exécution consécutive doit renvoyer `changed=0` pour l'ensemble des tâches système :
```bash
ansible-playbook -i inventory/production.ini site.yml
```
*(Résultat attendu : `ok=32 changed=0 failed=0`).*
