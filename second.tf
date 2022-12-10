# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#resource "<aws>_<resource_type>""<name>"
#key = "value"
# key2="value2"
#}
resource "aws_instance" "web" {
  ami           = "ami-08c40ec9ead489470"
  instance_type = "t2.micro"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Production"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet"
  }
}

#1. Create vpc_id

resource "aws_vpc" "prod-vpc"{
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "Production"
  }
}
#2 Create Internet Gateway

resource "aws_internet_gateway" "gw"{
  vpc_id = aws_vpc.prod-vpc.id"
}
#3. Create Custom Rout Table
resource "aws_route_table" "prod-route-table"{
  vpc_id = "aws_vpc.prod-vpc.id"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id

  tags = {
    Name = "prod"
  }
}
#4. Create a subnet
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "prod-subnet"
  }
}

#5. Associate subnet with Route table
resource "aws_route_table_association" "subnet-route"{
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#6. Create Security Group to allow port 22, 80, 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id"

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["o.o.o.o/0"]
  }
  
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["o.o.o.o/0"]
  }
  
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["o.o.o.o/0"]
  }
  
  

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
#7. Create a network interface with an ip in the subnet that was created in step 4
 
 resource "aws_network_interface" "web-server-james" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}
#8. Assign an elastic I.P to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-james.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}
#9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "web" {
  ami           = "ami-08c40ec9ead489470"
  instance_type = "t2.micro"
  availability_zone = "us-east-1b"
  key-name = "main-key"
  
  network_interface {
      device_index = 0
      network_interface = aws_network_interface.web-server-james.id
  }
  
  
  user_data = <<-EOF
              #l/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo This is Nubila Mbetigi James > /var/www/html/index.html'
              EOF
   }
    
#10. 