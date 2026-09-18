terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws" // provider aws
      version = "~> 5.0"        // version aws
    }
    tls = {
      source  = "hashicorp/tls" # provider tls pour la génération de clés ssh
      version = "~> 4.0"        # version tls
    }
    local = {
      source  = "hashicorp/local" # sauvegarder la clé privée SSH générée dans un fichier local sur notre ordinateur
      version = "~> 2.5"        # version local
    }
  }
}
