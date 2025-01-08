provider "aws" {
  region = "ap-southeast-1"
}

# 1. Creating a VPC

resource "aws_vpc" "quorum" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "quorum-network"
  }
}

# 2. Creating an intenet Gateway

resource "aws_internet_gateway" "GW_quorum-network" {
  vpc_id = aws_vpc.quorum.id

  tags = {
    Name = "IG_quorum-network"
  }
}

# 3. Create a Route Table

resource "aws_route_table" "RT_quorum-network" {

  vpc_id = aws_vpc.quorum.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.GW_quorum-network.id

  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.GW_quorum-network.id
  }

  tags = {
    Name = "RT_quorum-network"
  }
}

# 4. Creating a Subnet

resource "aws_subnet" "Subnet_quorum-network" {

  vpc_id            = aws_vpc.quorum.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-southeast-1a"
  depends_on        = [aws_internet_gateway.GW_quorum-network]
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet_quorum-network"
  }
}

# 5. Associate Subnet with Route Table

resource "aws_route_table_association" "RT_to_Subnet" {

  subnet_id      = aws_subnet.Subnet_quorum-network.id
  route_table_id = aws_route_table.RT_quorum-network.id
}

# 6. Create a Security Group to Allow posrts : 22, 80, 443
resource "aws_security_group" "SG_quorum-network" {

  name        = "SG_quorum-network"
  description = "Allow SSH, HTTP, HTTPS inbound traffic"
  vpc_id      = aws_vpc.quorum.id

  ingress {
    description = "JSON RPC from VPC"
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Quorum Explorer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Tessera Peering"
    from_port   = 9001
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Quorum Explorer"
    from_port   = 9081
    to_port     = 9081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Quorum Nodes Peering"
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG_quorum-network"
  }
}

# Create 4 instances t2.micro
resource "aws_network_interface" "ENI" {
  count           = 3
  subnet_id       = aws_subnet.Subnet_quorum-network.id
  private_ips     = ["10.0.0.${count.index + 10}"] # 10.0.0.10, 10.0.0.11, 10.0.0.12, 10.0.0.13
  security_groups = [aws_security_group.SG_quorum-network.id]
}

resource "aws_instance" "Instance_A" {
  count             = 3
  ami               = "ami-0ad522a4a529e7aa8"
  instance_type     = "t3.small"
  availability_zone = "ap-southeast-1a"
  key_name          = "quorum"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ENI[count.index].id # Reference the correct ENI
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y java-17-amazon-corretto-headless.x86_64
  EOF

  tags = {
    Name = "quorum-${count.index + 1}" # Unique name for each instance
  }
}


# Quorum Explorer

resource "aws_network_interface" "ENI_B" {

  subnet_id       = aws_subnet.Subnet_quorum-network.id
  private_ips     = ["10.0.0.20"]
  security_groups = [aws_security_group.SG_quorum-network.id]
}

resource "aws_instance" "Instance_B" {
  ami               = "ami-047126e50991d067b"
  instance_type     = "t2.micro"
  availability_zone = "ap-southeast-1a"
  key_name          = "quorum"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ENI_B.id
  }

  user_data = <<-EOF
    #!/bin/bash
    # Add Docker's official GPG key:
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable docker
  EOF

  tags = {
    Name = "quorum-explorer"
  }
}

# 8. Assign Elastic Ip to ENI
# resource "aws_eip" "EIP_A" {

#      vpc = true
#      network_interface = aws_network_interface.ENI_A.id
#      associate_with_private_ip = "10.0.0.10"
#      depends_on = [ aws_internet_gateway.GW_quorum-network, aws_instance.Instance_A]

#      tags = {
#         Name = "EIP_A"
#      }
# }

# 9. Create IAM Role to access S3
# resource "aws_iam_role" "EC2-S3" {
#   name = "EC2-S3"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF

#   tags = {
#       Name = "EC2-S3"
#   }
# }

// IAM Profile
# resource "aws_iam_instance_profile" "EC2-S3_Profile" {
#   name = "EC2-S3_Profile"
#   role = "${aws_iam_role.EC2-S3.name}"
# }

// IAM Policy
# resource "aws_iam_role_policy" "EC2-S3_Policy" {
#   name = "test_policy"
#   role = "${aws_iam_role.EC2-S3.id}"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:*"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# EOF

# }


# 10. Create Linux Server and install/enable Apache2
# resource "aws_instance" "Instance_A" {
#   ami                  = "ami-0947d2ba12ee1ff75"
#   instance_type        = "t2.micro"
#   availability_zone    = "ap-southeast-1"
#   key_name             = "quorum-network"
#   iam_instance_profile = "${aws_iam_instance_profile.EC2-S3_Profile.name}"

#   network_interface {
#     device_index = 0
#     network_interface_id = aws_network_interface.ENI_A.id
#   }

#   user_data = <<-EOF
#     #!/bin/bash
#     sudo yum update -y
#     sudo yum install -y curl java-17-amazon-corretto-headless.x86_64
#   EOF

#   tags = {
#     Name = "quorum-network_1.0"
#   }
# }

# 11. Enable VPC Enpoint

# resource "aws_vpc_endpoint" "s3" {
#     vpc_id = aws_vpc.quorum.id
#     service_name = "com.amazonaws.ap-southeast-1.s3"

#     tags = {
#         Name = "test"
#     }

# }