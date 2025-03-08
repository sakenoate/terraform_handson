
resource "aws_security_group" "ec2_test" {
  provider    = aws.tokyo
  name        = "ec2-test-sg"
  description = "Security group for EC2 test instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-test-sg"
  }
}

resource "aws_instance" "db_init" {
  provider      = aws.tokyo
  ami           = "ami-02e5504ea463e3f34"  # Amazon Linux 2023 AMI
  instance_type = "t2.micro"
  key_name      = "ec2test"
  subnet_id     = aws_subnet.public_1.id
  
  vpc_security_group_ids = [aws_security_group.ec2_test.id]
  
  user_data = base64encode(<<EOF
#!/bin/bash
sudo yum update -y
sudo yum install https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm -y
sudo yum install -y mysql 
sudo mysql -h ${aws_db_instance.main.address} -u ${var.DatabaseUsername} -p'${var.DatabasePassword}' <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS ${var.DatabaseName};
USE ${var.DatabaseName};
CREATE TABLE Reservations (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  company_name VARCHAR(255) NOT NULL,
  reservation_date DATE NOT NULL,
  number_of_people INT NOT NULL
);
INSERT INTO Reservations (company_name, reservation_date, number_of_people)
VALUES ('株式会社テスト', '2024-04-21', 5);
SELECT * FROM Reservations;
MYSQL_SCRIPT
sudo shutdown -h now  # Shutdown the instance after execution
EOF
  )
  
  tags = {
    Name = "db-init-instance"
  }
  
  depends_on = [aws_db_instance.main]
}
