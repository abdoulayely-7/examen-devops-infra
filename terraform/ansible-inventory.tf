# Génération automatique de l'inventaire Ansible avec l'IP publique de l'EC2 et la clé SSH
resource "local_file" "ansible_inventory" {
  content = <<-EOF
# Inventaire Ansible généré automatiquement par Terraform
# Ne pas modifier manuellement

[production]
prod-ec2 ansible_host=${aws_instance.prod.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${pathexpand(var.ssh_private_key_path)} ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[production:vars] // Variables globales pour le groupe d'hôtes
ansible_python_interpreter=/usr/bin/python3
EOF

  filename        = "${path.module}/../ansible/inventory/production.ini"
  file_permission = "0644"
}
