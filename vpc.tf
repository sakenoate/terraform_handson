
resource "aws_vpc" "main" {
  provider             = aws.tokyo
  cidr_block           = "10.0.0.0/21"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = var.VPCName
  }
}

resource "aws_internet_gateway" "main" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  
  tags = {
    Name = "reservation-igw"
  }
}

resource "aws_eip" "nat" {
  provider = aws.tokyo
  domain   = "vpc"
}

resource "aws_nat_gateway" "main" {
  provider      = aws.tokyo
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  
  depends_on = [aws_internet_gateway.main]
}

# Public Subnets
resource "aws_subnet" "public_1" {
  provider                = aws.tokyo
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "elb-subnet-01"
  }
}

resource "aws_subnet" "public_2" {
  provider                = aws.tokyo
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.6.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  
  tags = {
    Name = "elb-subnet-02"
  }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  provider          = aws.tokyo
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "api-subnet-01"
  }
}

resource "aws_subnet" "private_2" {
  provider          = aws.tokyo
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  
  tags = {
    Name = "api-subnet-02"
  }
}

resource "aws_subnet" "private_3" {
  provider          = aws.tokyo
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "db-subnet-01"
  }
}

resource "aws_subnet" "private_4" {
  provider          = aws.tokyo
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  
  tags = {
    Name = "db-subnet-02"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  
  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table" "private" {
  provider = aws.tokyo
  vpc_id   = aws_vpc.main.id
  
  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_route" "public_internet_gateway" {
  provider               = aws.tokyo
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "private_nat_gateway" {
  provider               = aws.tokyo
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# Route Table Associations
resource "aws_route_table_association" "public_1" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  provider       = aws.tokyo
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "alb" {
  provider    = aws.tokyo
  name        = "alb-sg"
  description = "Security group for API ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_security_group" "api_server" {
  provider    = aws.tokyo
  name        = "api-sg"
  description = "Security group for API servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb.id]
    description              = "Allow HTTP from ALB only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "api-sg"
  }
}

data "aws_availability_zones" "available" {
  provider = aws.tokyo
  state    = "available"
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_2.id
}

output "private_subnet_1_id" {
  value = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  value = aws_subnet.private_2.id
}

output "private_subnet_3_id" {
  value = aws_subnet.private_3.id
}

output "private_subnet_4_id" {
  value = aws_subnet.private_4.id
}

output "api_server_security_group_id" {
  value = aws_security_group.api_server.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}
