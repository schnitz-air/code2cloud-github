# network.tf

# --------------------------------------------------------------
# VPC (Virtual Private Cloud)
# --------------------------------------------------------------

# Defines the main Virtual Private Cloud (VPC), which is the isolated network for the EKS cluster.
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name = "${var.cluster_name}-VPC"
  }
}

# --------------------------------------------------------------
# Subnets
# --------------------------------------------------------------

# Defines a public subnet in Availability Zone 'a'. Public-facing resources like load balancers go here.
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.cluster_name}-public-subnet-1"
    "kubernetes.io/role/elb" = "1"
  }
}

# Defines a public subnet in Availability Zone 'b'.
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.cluster_name}-public-subnet-2"
    "kubernetes.io/role/elb" = "1"
  }
}

# Defines a private subnet in Availability Zone 'a'. Internal resources like EKS nodes go here.
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                              = "${var.cluster_name}-private-subnet-1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Defines a private subnet in Availability Zone 'b'.
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                              = "${var.cluster_name}-private-subnet-2"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


# --------------------------------------------------------------
# Gateways
# --------------------------------------------------------------

# Creates an Internet Gateway to allow communication between the VPC and the internet.
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name = "${var.cluster_name}-IGW"
  }
}

# Allocates a static public IP address for the first NAT Gateway.
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"
  tags   = { Name = "${var.cluster_name}-NAT1-EIP" }
}

# Allocates a static public IP address for the second NAT Gateway.
resource "aws_eip" "nat_eip_2" {
  domain = "vpc"
  tags   = { Name = "${var.cluster_name}-NAT2-EIP" }
}

# Creates a NAT Gateway in the first public subnet for outbound internet access from private subnets.
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "${var.cluster_name}-NAT1" }
  depends_on    = [aws_internet_gateway.k8s_igw]
}

# Creates a second NAT Gateway in the second public subnet for high availability.
resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_2.id
  tags          = { Name = "${var.cluster_name}-NAT2" }
  depends_on    = [aws_internet_gateway.k8s_igw]
}


# --------------------------------------------------------------
# Routing
# --------------------------------------------------------------

# Defines a route table for the public subnets.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags   = { Name = "${var.cluster_name}-Public-RT" }
}

# Adds a route to the public route table that directs internet-bound traffic to the Internet Gateway.
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.k8s_igw.id
}

# Associates the first public subnet with the public route table.
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# Associates the second public subnet with the public route table.
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


# Defines a dedicated route table for the first private subnet.
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags   = { Name = "${var.cluster_name}-Private-RT-1" }
}

# Adds a route that directs internet-bound traffic from the private subnet to the first NAT Gateway.
resource "aws_route" "private_1_nat_access" {
  route_table_id         = aws_route_table.private_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
}

# Associates the first private subnet with its dedicated route table.
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}


# Defines a dedicated route table for the second private subnet.
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags   = { Name = "${var.cluster_name}-Private-RT-2" }
}

# Adds a route that directs internet-bound traffic from the private subnet to the second NAT Gateway.
resource "aws_route" "private_2_nat_access" {
  route_table_id         = aws_route_table.private_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_2.id
}

# Associates the second private subnet with its dedicated route table.
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}