# Infrastructure as Code — AWS avec Terraform

Ce module Terraform automatise le provisionnement complet de l'infrastructure Cloud AWS pour le déploiement de la stack DevOps de production (Traefik, Prometheus, Grafana, cAdvisor, Node Exporter, SonarQube, et Backend Spring Boot).

---

## 1. Vue d'ensemble & Architecture Cloud

L'infrastructure est déployée sur la région **AWS `us-east-1` (N. Virginia)** en respectant strictement les contraintes de coût (Free Tier Eligible) :

```text
                               AWS Cloud (us-east-1)
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │ VPC (10.0.0.0/16)                                                           │
 │                                                                             │
 │   Public Subnet (10.0.1.0/24 - us-east-1a)                                  │
 │   ┌───────────────────────────────────────────────────────────────────────┐ │
 │   │ Internet Gateway (IGW) ◄─── Route Table (0.0.0.0/0 -> IGW)            │ │
 │   │                                                                       │ │
 │   │ Security Group (devops-prod-sg)                                       │ │
 │   │  ├── Ingress 22/tcp  : Ouvert au runner GitHub Actions & Admin        │ │
 │   │  ├── Ingress 80/tcp  : Ouvert au public (0.0.0.0/0) -> Traefik HTTP   │ │
 │   │  ├── Ingress 443/tcp : Ouvert au public (0.0.0.0/0) -> Traefik HTTPS  │ │
 │   │  └── Egress All      : Tout trafic sortant autorisé (0.0.0.0/0)       │ │
 │   │                                                                       │ │
 │   │ Instance EC2 (devops-prod-server)                                     │ │
 │   │  ├── Type : t3.small (2 vCPU, 2 Go RAM)                              │ │
 │   │  ├── OS : Ubuntu Server 24.04 LTS (Noble Numbat - ami-025d99823a4...) │ │
 │   │  ├── Stockage : 30 Go GP3 EBS (Free Tier)                             │ │
 │   │  ├── Clé SSH : ED25519 générée dynamiquement                         │ │
 │   │  └── IP Publique : Dynamique (pas d'Elastic IP payante)               │ │
 │   └───────────────────────────────────────────────────────────────────────┘ │
 └─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Dépendances et interactions avec les autres dossiers

Terraform constitue la couche **Day 0** (fondation de l'infrastructure). Il possède deux liaisons directes avec le reste de la stack :

1. **Liaison avec `ansible/`** :
   - Le fichier [`ansible-inventory.tf`](./ansible-inventory.tf) génère **automatiquement** le fichier d'inventaire [`ansible/inventory/production.ini`](../ansible/inventory/production.ini) dès la fin du `terraform apply`.
   - Cet inventaire injecte l'IP publique dynamique de l'EC2, l'utilisateur SSH (`ubuntu`), et le chemin vers la clé privée SSH générée.
2. **Liaison avec `.github/workflows/` (GitHub Actions)** :
   - L'IP publique produite en output (`prod_public_ip`) doit être renseignée dans le GitHub Secret `EC2_HOST`.
   - La clé privée générée (`~/.ssh/devops-prod-key`) doit être renseignée dans le GitHub Secret `EC2_SSH_PRIVATE_KEY` pour permettre au pipeline CD de se connecter en SSH et déployer l'application.
3. **Liaison avec DuckDNS** :
   - Comme aucune Elastic IP payante n'est allouée, l'IP publique dynamique affichée en output doit être associée aux sous-domaines sur [duckdns.org](https://www.duckdns.org).

---

## 3. Détail des fichiers et ressources Terraform

| Fichier | Ressource Terraform | Description technique |
| :--- | :--- | :--- |
| **`versions.tf`** | `terraform { required_version, required_providers }` | Fixe Terraform à `>= 1.5.0`, provider `hashicorp/aws ~> 5.0`, `hashicorp/tls ~> 4.0`, et `hashicorp/local ~> 2.4`. |
| **`provider.tf`** | `provider "aws"` | Configure la région cible (`var.aws_region`, par défaut `us-east-1`). |
| **`vpc.tf`** | `aws_vpc.main` | Crée le Virtual Private Cloud avec le bloc CIDR `10.0.0.0/16`, avec support DNS activé (`enable_dns_hostnames = true`). |
| **`subnet.tf`** | `aws_subnet.public` | Crée le subnet public `10.0.1.0/24` dans la zone de disponibilité `us-east-1a`, avec attribution automatique d'IP publique activée. |
| **`internet-gateway.tf`**| `aws_internet_gateway.gw` | Crée la passerelle Internet rattachée au VPC pour permettre les flux entrants et sortants vers Internet. |
| **`route-table.tf`** | `aws_route_table.public` & association | Définit la table de routage par défaut envoyant `0.0.0.0/0` vers l'Internet Gateway et l'associe au subnet public. |
| **`security-group.tf`** | `aws_security_group.prod` | Pare-feu de niveau couche 4 réseau : restreint les flux stricts (Ports 80 et 443 pour Traefik, Port 22 pour SSH). Les ports internes applicatifs (8080, 9000, 9090, 3000) sont **strictement bloqués** depuis l'extérieur. |
| **`key-pair.tf`** | `tls_private_key.ssh` & `aws_key_pair.deployer` | Génère une paire de clés cryptographiques **ED25519** en mémoire. Sauvegarde automatiquement la clé privée dans `~/.ssh/devops-prod-key` avec permissions `0600` et enregistre la clé publique sur AWS. |
| **`ec2.tf`** | `aws_instance.prod` | Provisionne l'instance `t3.small` avec un disque root EBS de 30 Go `gp3` (taux d'IOPS garanti). |
| **`ansible-inventory.tf`**| `local_file.ansible_inventory` | Déclenche la création du fichier d'inventaire Ansible à chaque modification d'IP. |
| **`variables.tf`** | `variable "..."` | Déclare les variables d'entrée (région, type d'instance, taille disque, CIDR admin). |
| **`outputs.tf`** | `output "..."` | Expose l'IP publique, le DNS public, l'ID d'instance, le chemin de la clé SSH et le chemin de l'inventaire. |
| **`terraform.tfvars`** | Valeurs effectives | Fichier local contenant les variables spécifiques (région, admin IP, etc.). |

---

## 4. Guide des commandes opérationnelles

### Prérequis
- Terraform CLI (v1.5+) installé.
- AWS CLI configuré (`aws configure`) avec des identifiants ayant les droits IAM suffisants (VPC, EC2, KeyPair).

### Initialisation
```bash
cd terraform
terraform init
```

### Planification (Dry Run)
```bash
terraform plan
```

### Déploiement de l'infrastructure
```bash
terraform apply -auto-approve
```

### Visualisation des sorties (Outputs)
```bash
terraform output
```

### Connexion SSH directe à l'instance
```bash
ssh -i ~/.ssh/devops-prod-key ubuntu@$(terraform output -raw prod_public_ip)
```

### Destruction complète de l'infrastructure
```bash
terraform destroy -auto-approve
```

> **Important en cas de recréation (`destroy` + `apply`)** :  
> L'IP publique ayant changé, il faut impérativement répercuter la nouvelle valeur dans **DuckDNS** et dans le secret GitHub **`EC2_HOST`**.
