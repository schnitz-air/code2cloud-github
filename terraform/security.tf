# security.tf

# Data source to get the current AWS Account ID, used for dynamic IAM policies.
data "aws_caller_identity" "current" {}

# --------------------------------------------------------------
# Account-Level Security Settings
# --------------------------------------------------------------

# Creates an IAM Access Analyzer to monitor for unintended external access to resources.
resource "aws_accessanalyzer_analyzer" "external_access" {
  analyzer_name = "ExternalIAMAccessAnalyzer"
  type          = "ACCOUNT"
  tags = {
    yor_trace = "a4174ede-6f57-4284-b9fd-4c8e86d7f1e5"
  }
}

# Configures account-wide settings to block all public access from security groups.
resource "aws_vpc_block_public_access" "account_wide" {
  # This will block all new public security group rules, with no exceptions.
  block_public_security_group_rules = true
}

# Enables default encryption for all new EBS volumes created in the region.
resource "aws_ebs_encryption_by_default" "account_wide" {
  enabled = true
}

# Creates a customer-managed KMS key for encrypting CloudTrail logs.
resource "aws_kms_key" "cloudtrail_key" {
  description         = "KMS key for CloudTrail logs encryption"
  enable_key_rotation = false

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "Enable IAM User Permissions",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = "kms:*",
        Resource  = "*"
      },
      {
        Sid       = "Allow CloudTrail to Encrypt Logs",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = ["kms:GenerateDataKey", "kms:Encrypt"],
        Resource  = "*"
      },
      {
        Sid       = "Allow S3 Access",
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
        Action    = ["kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"],
        Resource  = "*"
      }
    ]
  })

  tags = {
    managed_by = "paloaltonetworks"
    yor_trace  = "74945f95-7de1-41c9-8257-e2c1a71d5bdc"
  }
}


# --------------------------------------------------------------
# EKS Cluster Security Groups
# --------------------------------------------------------------

# Defines the primary security group for the EKS cluster's control plane.
resource "aws_security_group" "eks_control_plane_sg" {
  name        = "${var.cluster_name}-control-plane-sg"
  description = "Security group for the EKS cluster control plane."
  vpc_id      = aws_vpc.k8s_vpc.id

  tags = {
    Name      = "${var.cluster_name}-control-plane-sg"
    yor_trace = "ce91c912-4314-45b5-bffb-20f547e16398"
  }
}

# Defines the security group for the EKS worker nodes.
resource "aws_security_group" "eks_node_sg" {
  name        = "${var.cluster_name}-EKSNodeSG"
  description = "Security group for the EKS worker nodes."
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "Allow all traffic between EKS worker nodes."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  ingress {
    description              = "Allow Kubelet traffic from EKS control plane to worker nodes."
    from_port                = 10250
    to_port                  = 10250
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.eks_control_plane_sg.id
  }
  ingress {
    description              = "Allow API server traffic from EKS control plane to worker nodes."
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.eks_control_plane_sg.id
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.cluster_name}-EKSNodeSG"
    yor_trace = "13e249d9-3c5f-41fa-bbb5-351e948e3cfe"
  }
}

# Defines a shared security group for general communication within the cluster.
resource "aws_security_group" "eks_shared_sg" {
  name        = "eks-cluster-sg-${var.cluster_name}"
  description = "EKS created security group for control plane ENIs and managed workloads."
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                        = "eks-cluster-sg-${var.cluster_name}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    yor_trace                                   = "7baba9ed-9a90-4989-bb38-bad48762e434"
  }
}


# --------------------------------------------------------------
# Default Security Group Management (Hardened)
# --------------------------------------------------------------

# Manages the default security group for the VPC, hardening it by removing all default rules.
resource "aws_default_security_group" "k8s_vpc_default" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name      = "${var.cluster_name}-default-sg"
    yor_trace = "6ace4199-43d0-48b6-bfff-8b54063cce58"
  }
}