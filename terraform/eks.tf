# eks.tf

# Defines the EKS (Kubernetes) cluster control plane.
resource "aws_eks_cluster" "my_cluster" {
  name    = var.cluster_name
  version = "1.30"

  # Reference the IAM role created in iam.tf
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    # Place the EKS control plane ENIs in your private subnets for security.
    subnet_ids = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id,
    ]

    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    # Reference the control plane security group from security.tf
    security_group_ids = [aws_security_group.eks_control_plane_sg.id]
  }

  enabled_cluster_log_types = []

  tags = {
    Name                            = var.cluster_name
    "aws:cloudformation:logical-id" = "EKSCluster"
    "aws:cloudformation:stack-name" = "eks-cluster"
    yor_trace                       = "4bb1d221-fd9b-452f-a22f-2edc482dc4c7"
  }
}