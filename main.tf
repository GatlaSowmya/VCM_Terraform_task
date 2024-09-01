
# Create an IAM user
resource "aws_iam_user" "nithins" {
  name = "nithins"
}

# Create an IAM policy
resource "aws_iam_policy" "best-policy" {
  name        = "best-policy"
  description = "An example policy"
  policy      = jsonencode({
    "Version"   : "2012-10-17",
    "Statement" : [
      {
        "Effect"   : "Allow",
        "Action"   : "*",
        "Resource" : "*"
      }
    ]
  })
}

# Attach IAM policy to IAM user
resource "aws_iam_user_policy_attachment" "admin_policy_attachment" {
  user       = aws_iam_user.nithins.name
  policy_arn = aws_iam_policy.best-policy.arn
}

# Create a login profile for the IAM user
resource "aws_iam_user_login_profile" "admin_login_profile" {
  user                    = aws_iam_user.nithins.name
  password_reset_required = true
}
 
# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id                   = aws_vpc.main_vpc.id
  cidr_block               = "10.0.1.0/24"
  availability_zone        = "us-east-1a"
  map_public_ip_on_launch  = true  # Enable public IP assignment by default

  tags = {
    Name = "main-subnet"
  }
}

# Create an EC2 key pair
resource "aws_key_pair" "main_key" {
  key_name   = "VCM_Keypair"
  public_key = file("./sowmya.pub")  # Replace with the path to your public key file
}

# Create EC2 Instance
resource "aws_instance" "main_instance" {
  ami                         = "ami-0e86e20dae9224db8"  # Amazon Linux 2 AMI ID for your region
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.main_key.key_name
  subnet_id                   = aws_subnet.main_subnet.id
  vpc_security_group_ids      = [aws_security_group.main_sg.id]
  associate_public_ip_address = true  # Explicitly request a public IP

  tags = {
    Name = "main-instance"
  }
}


# Create Security Group
resource "aws_security_group" "main_sg" {
  name        = "main-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "main-sg"
  }
}
# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

# Create a Route Table for the VPC
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-route-table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.public.id
}

# Create a route in the public route table (already provided by you)
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
