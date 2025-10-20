#resource "aws_instance" "ec2_instance" {
#  # NOTE: The AMI ID is still hardcoded. For a more robust setup,
#  # consider using a map variable to look up AMIs by region.
#  ami = "ami-091e1eed890c3f1d1"
#
#  # Use variables for instance type and key name
#  instance_type = var.instance_type
#  key_name      = var.key_name
#
#  # NOTE: This IAM profile ARN is still hardcoded.
#  iam_instance_profile = "arn:aws:iam::980573775279:instance-profile/eks-5ecb8bcc-f19e-43e1-a3ef-6c29d8215aba"
#
#  # Reference the subnet created above
#  subnet_id = aws_subnet.k8s_subnet_2.id
#
#  # NOTE: The Security Group ID is still hardcoded.
#  # This should reference an aws_security_group resource.
#  vpc_security_group_ids = [
#    "sg-00798d49dafea46e1"
#  ]
#
#  metadata_options {
#    http_endpoint               = "enabled"
#    http_tokens                 = "optional"
#    http_put_response_hop_limit = 2
#  }
#
#  root_block_device {
#    delete_on_termination = true
#  }
#
#  tags = {
#    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
#    "aws:eks:cluster-name"                   = var.cluster_name
#    "eks:nodegroup-name"                     = "my-eks-nodegroup"
#    "k8s.io/cluster-autoscaler/enabled"      = "true"
#    "eks:cluster-name"                       = var.cluster_name
#    "kubernetes.io/cluster/${var.cluster_name}"     = "owned"
#  }
#}

# compute.tf

# Data source to dynamically find the latest Amazon EKS-optimized AMI.
data "aws_ami" "eks_node" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.my_cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # AWS account ID for EKS-optimized AMIs
}

# Defines a single EC2 instance to serve as an EKS worker node.
resource "aws_instance" "eks_node" {
  ami = data.aws_ami.eks_node.id

  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile = aws_iam_instance_profile.eks_node.name

  subnet_id = aws_subnet.private_1.id

  vpc_security_group_ids = [
    aws_security_group.eks_node_sg.id,
    aws_security_group.eks_shared_sg.id,
  ]

  # This script runs on startup to register the node with the EKS cluster.
  user_data = <<-EOF
              #!/bin/bash
              set -o xtrace
              /etc/eks/bootstrap.sh ${aws_eks_cluster.my_cluster.name} --b64-cluster-ca '${aws_eks_cluster.my_cluster.certificate_authority[0].data}' --apiserver-endpoint '${aws_eks_cluster.my_cluster.endpoint}'
              EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
    encrypted   = true
  }

  tags = {
    Name                                        = "${var.cluster_name}-worker-node"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    yor_trace                                   = "90431c16-0edf-4f72-86a8-65b4cbd93720"
  }
}