resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Permet la résolution DNS des noms d'hôtes
  enable_dns_support   = true # Permet la résolution DNS

  tags = {
    Name = "devops-prod-vpc" # Nom de la VPC
  }
}
