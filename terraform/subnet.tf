resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true # Assign un IP publique automatiquement à chaque instance lancée dans cette subnet

  tags = {
    Name = "devops-prod-public-subnet"
  }
}
