#Step1- Creating VPC
resource "aws_vpc" "VPC_nonprod" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"
}

#Step 2- Adding public subnet1
resource "aws_subnet" "public_sn1" {
  vpc_id            = aws_vpc.VPC_nonprod.id
  cidr_block        = var.public_cidrs[0]
  availability_zone = var.availability_zone[0]
}

#Step 3- Adding public subnet2 
resource "aws_subnet" "public_sn2" {
  vpc_id            = aws_vpc.VPC_nonprod.id
  cidr_block        = var.public_cidrs[1]
  availability_zone = var.availability_zone[1]
}

#Step 4: Creating Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC_nonprod.id
}

#Step 5: Routine Table to igw

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.VPC_nonprod.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#Step 6: Associating Routine table with subnet
#For subnet 1
resource "aws_route_table_association" "link1" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_sn1.id
}
#For subnet 2
resource "aws_route_table_association" "link2" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_sn2.id
}

# Output

output "public_subnet_1" {
  value = aws_subnet.public_sn1.id
}

output "public_subnet_2" {
  value = aws_subnet.public_sn2.id
}

output "web_sg2" {
  value = aws_security_group.wb_sg2.id
}

              
