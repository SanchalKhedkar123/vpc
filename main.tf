#############VPC#############

provider "aws" {
    region = "ap-south-1"
}

resource "aws_vpc" "vpc_1" {
  cidr_block = "10.0.0.0/16"
    tags = {
    Name = "vpcsan"
  }
}
##################SUBNET##############

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc_1.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc_1.id
  cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1b"

  tags = {
    Name = "private_subnet"
  }
}
resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.vpc_1.id
  cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1b"

  tags = {
    Name = "private_subnet_1"
  }
}

############IGW###############

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "igw"
  }
}

###############RTW##############

resource "aws_route_table" "rtw" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rtw"
  }
}

############ROUTE edit##############

resource "aws_route" "my_route" {
  route_table_id            = aws_route_table.rtw.id
  destination_cidr_block    = "0.0.0.0/0"  # Destination CIDR block (all traffic)
  gateway_id                = aws_internet_gateway.igw.id  # Target: Internet Gateway
}

#################SUBNET_ASSOCIATION#################

resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rtw.id
}

################SECURITY GROUP###############


resource "aws_security_group" "sg" {
  name        = "terraform_SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc_1.id

  dynamic "ingress" {

  for_each = [3306,80,8080,22]
  iterator = port
  content {
    description = "http from VPC"
    from_port   = port.value
    to_port     = port.value
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  

  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }



  }
}
}
####################INSTANCE################


resource "aws_instance" "ins" {
  ami           = "ami-0eb260c4d5475b901"
  instance_type = "t2.micro"
  key_name   = "london"
  subnet_id      = aws_subnet.private_subnet.id
   security_groups = [aws_security_group.sg.id]
    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF
  tags = {
    Name = "intance_1"
  }
}
##############################autoscalling##########

resource "aws_autoscaling_group" "nginx_asg" {
  launch_configuration = aws_launch_configuration.nginx.id
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.public.id]

  tag {
    key                 = "Name"
    value               = "nginx-instance"
    propagate_at_launch = true
  }
