output "prod_public_ip" {
  description = "IPv4 publique attribuée à l instance EC2"
  value       = aws_instance.prod.public_ip
}

output "prod_public_dns" {
  description = "Nom DNS public attribué par AWS"
  value       = aws_instance.prod.public_dns
}

output "prod_instance_id" {
  description = "ID unique de l instance EC2 de production"
  value       = aws_instance.prod.id
}

output "ssh_private_key_path" {
  description = "Chemin de la clé privée SSH générée automatiquement par Terraform"
  value       = pathexpand(var.ssh_private_key_path)
}

output "ansible_inventory_path" {
  description = "Chemin du fichier d inventaire Ansible généré automatiquement"
  value       = local_file.ansible_inventory.filename
}
