
resource "aws_db_subnet_group" "main" {
  provider   = aws.tokyo
  name       = "reservation-db-subnet-group"
  subnet_ids = [aws_subnet.private_3.id, aws_subnet.private_4.id]

  tags = {
    Name = "reservation-db-subnet-group"
  }
}

resource "aws_security_group" "db" {
  provider    = aws.tokyo
  name        = "db-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.DBinboundCidrIPs]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

resource "aws_db_instance" "main" {
  provider                = aws.tokyo
  identifier              = "reservation-db-instance"
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = var.DatabaseName
  username                = var.DatabaseUsername
  password                = var.DatabasePassword
  parameter_group_name    = "default.mysql8.0"
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  skip_final_snapshot     = true
  multi_az                = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "reservation-db"
  }
}

output "db_endpoint" {
  value = aws_db_instance.main.address
}
