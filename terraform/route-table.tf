resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route { # Création de la route par défaut
    cidr_block = "0.0.0.0/0" # Route par défaut vers l'Internet Gateway
    gateway_id = aws_internet_gateway.gw.id  # Id de l'Internet Gateway
  }

  tags = {
    Name = "devops-prod-public-rt"
  }
}

resource "aws_route_table_association" "public" { # Association de la table de routage à la subnet publique
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
