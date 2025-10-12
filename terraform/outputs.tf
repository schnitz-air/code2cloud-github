# outputs.tf

# --- VPC and Networking Outputs ---

output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.k8s_vpc.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id,
  ]
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets."
  value = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id,
  ]
}

# --- EKS Cluster Outputs ---

output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.my_cluster.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API server."
  value       = aws_eks_cluster.my_cluster.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster (for kubeconfig)."
  value       = aws_eks_cluster.my_cluster.certificate_authority[0].data
  sensitive   = true
}

output "eks_node_security_group_id" {
  description = "The ID of the security group for the EKS worker nodes."
  value       = aws_security_group.eks_node_sg.id
}

# --- S3 and ECR Outputs ---

output "cloudtrail_logs_bucket_name" {
  description = "The name of the S3 bucket for CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "ecr_flask_repo_url" {
  description = "The URL of the Flask webserver ECR repository."
  value       = aws_ecr_repository.flask_webserver_repo.repository_url
}

# --- Lambda Function Outputs ---

output "empty_bucket_lambda_arn" {
  description = "The ARN of the Empty Bucket Lambda function."
  value       = aws_lambda_function.empty_bucket_lambda.arn
}