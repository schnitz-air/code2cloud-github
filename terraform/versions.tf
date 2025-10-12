# versions.tf

terraform {
  required_version = ">= 1.0" # Specifies the minimum Terraform version needed

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use any version in the 5.x series
    }
  }
}

# You should also add the provider configuration here
provider "aws" {
  region = var.aws_region
}
