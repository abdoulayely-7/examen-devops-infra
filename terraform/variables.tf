variable "aws_region" {
  description = "Région AWS pour déployer les ressources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Plage CIDR pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Plage CIDR pour le subnet public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Zone de disponibilité AWS pour le subnet"
  type        = string
  default     = "us-east-1a"
}

variable "admin_cidr" {
  description = "Adresse IP publique autorisée pour l accès SSH (/32)"
  type        = string
}

variable "instance_type" {
  description = "Type d instance EC2 (t3.medium recommandé pour Docker + SonarQube + Prometheus + Grafana)"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Taille du disque EBS racine en Go"
  type        = number
  default     = 30
}

variable "ssh_private_key_path" {
  description = "Chemin local pour sauvegarder la clé privée SSH générée par Terraform"
  type        = string
  default     = "~/.ssh/devops-prod-key"
}
