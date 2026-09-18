provider "aws" {
  region = var.aws_region

  default_tags { #default_tags est utilisé pour ajouter des tags à toutes les ressources créées par Terraform
    tags = {
      Project     = "DevOps-Exam"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}
