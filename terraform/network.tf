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
    Name      = "${var.cluster_name}-VPC"
    yor_trace = "a6984cd3-0504-40d2-9145-462394d34948"
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
    yor_trace                = "2265ca48-5ec5-4eca-927e-ef714787825f"
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
    yor_trace                = "42bde467-c9e9-49bc-8182-177fbc170ab1"
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
    yor_trace                         = "0f702fcd-da42-4f9b-b0f6-ca243fc73e0e"
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
    yor_trace                         = "206bb654-53df-457e-85ac-c9e0d26ae61e"
  }
}


# --------------------------------------------------------------
# Gateways
# --------------------------------------------------------------

# Creates an Internet Gateway to allow communication between the VPC and the internet.
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = {
    Name      = "${var.cluster_name}-IGW"
    yor_trace = "80841cf5-ccc3-4081-937b-cc28e7fba0a1"
  }
}

# Allocates a static public IP address for the first NAT Gateway.
resource "aws_eip" "nat_eip_1" {
  domain = "vpc"
  tags = { Name = "${var.cluster_name}-NAT1-EIP"
    yor_trace = "a78a1285-ff97-4689-9085-83b325e98bec"
  }
}

# Allocates a static public IP address for the second NAT Gateway.
resource "aws_eip" "nat_eip_2" {
  domain = "vpc"
  tags = { Name = "${var.cluster_name}-NAT2-EIP"
    yor_trace = "d9c3ef4d-4670-49da-adbf-7464bd3472b7"
  }
}

# Creates a NAT Gateway in the first public subnet for outbound internet access from private subnets.
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_1.id
  tags = { Name = "${var.cluster_name}-NAT1"
    yor_trace = "04c561be-71d5-4e7d-9a81-3aacf3226ee7"
  }
  depends_on = [aws_internet_gateway.k8s_igw]
}

# Creates a second NAT Gateway in the second public subnet for high availability.
resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_2.id
  tags = { Name = "${var.cluster_name}-NAT2"
    yor_trace = "15907bb5-1ddb-4143-bf0a-01c1e84a05d7"
  }
  depends_on = [aws_internet_gateway.k8s_igw]
}


# --------------------------------------------------------------
# Routing
# --------------------------------------------------------------

# Defines a route table for the public subnets.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = { Name = "${var.cluster_name}-Public-RT"
    yor_trace = "01296ba5-e2d3-4c8d-a0a7-4e57eae19f27"
  }
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
  tags = { Name = "${var.cluster_name}-Private-RT-1"
    yor_trace = "66bbd369-07a2-40aa-a8d4-0d70260eb063"
  }
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
  tags = { Name = "${var.cluster_name}-Private-RT-2"
    yor_trace = "74914750-8b52-4d1c-b3ac-4814c62d118e"
  }
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