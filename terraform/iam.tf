# iam.tf

# --------------------------------------------------------------
# IAM Roles & Policies for EKS
# --------------------------------------------------------------

# Defines the IAM role that the EKS control plane will assume.
resource "aws_iam_role" "eks_cluster" {
  name_prefix = "eks-cluster-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

# Attaches the required AWS-managed policy for EKS clusters to the role.
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}


# Defines the IAM role that EKS worker nodes (EC2 instances) will assume.
resource "aws_iam_role" "eks_node" {
  name_prefix = "eks-node-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Creates an instance profile, which is a container for the IAM role that EC2 can use.
resource "aws_iam_instance_profile" "eks_node" {
  name_prefix = "eks-node-profile-"
  role        = aws_iam_role.eks_node.name
}

# Attaches the standard EKS worker node policy.
resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

# Attaches the CNI policy, allowing pods to get IP addresses from the VPC.
resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

# Attaches a read-only policy for ECR, allowing nodes to pull container images.
resource "aws_iam_role_policy_attachment" "eks_node_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}


# --------------------------------------------------------------
# IAM Roles & Policies for Lambda
# --------------------------------------------------------------

# A data source to create a reusable IAM trust policy for all Lambda functions.
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    action = "sts:AssumeRole"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Defines an execution role for the 'cortex_custom_lambda' function.
resource "aws_iam_role" "cortex_custom_lambda" {
  name_prefix        = "cortex-custom-lambda-role-"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Attaches the basic execution policy, allowing the function to write to CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "cortex_custom_lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.cortex_custom_lambda.name
}

# Defines an execution role for the 'empty_bucket_lambda' function.
resource "aws_iam_role" "empty_bucket_lambda" {
  name_prefix        = "empty-bucket-lambda-role-"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Attaches the basic execution policy.
resource "aws_iam_role_policy_attachment" "empty_bucket_lambda_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.empty_bucket_lambda.name
}

# Defines an execution role for the second 'cortex_custom_lambda' function.
resource "aws_iam_role" "cortex_custom_lambda_2" {
  name_prefix        = "cortex-custom-lambda-2-role-"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}