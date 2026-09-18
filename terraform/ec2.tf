data "aws_ami" "ubuntu" { # Recherche de l'image Ubuntu la plus récente
  most_recent = true
  owners      = ["099720109477"] # identifiant de Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter { 
    name   = "virtualization-type" 
    values = ["hvm"] # Type de virtualisation HVM (Hardware Virtual Machine)  
  }
}

resource "aws_instance" "prod" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.prod.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true # Assign un IP publique automatiquement

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true

    tags = {
      Name = "devops-prod-root-ebs"
    }
  }

  tags = {
    Name = "devops-prod-ec2"
  }
}
