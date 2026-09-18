# Génération automatique d'une clé SSH ED25519 par Terraform (aucune clé en dur)
resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

# Enregistrement de la clé publique correspondante sur AWS EC2
resource "aws_key_pair" "deployer" {
  key_name   = "devops-prod-key"
  public_key = tls_private_key.ssh.public_key_openssh

  tags = {
    Name = "devops-prod-key"
  }
}

# Sauvegarde automatique de la clé privée sur la machine locale avec permissions strictes 0600
resource "local_sensitive_file" "ssh_private_key" {
  content         = tls_private_key.ssh.private_key_openssh
  filename        = pathexpand(var.ssh_private_key_path)
  file_permission = "0600"
}

# Sauvegarde de la clé publique au format OpenSSH
resource "local_file" "ssh_public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = pathexpand("${var.ssh_private_key_path}.pub")
  file_permission = "0644"
}
