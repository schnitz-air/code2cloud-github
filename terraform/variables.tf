# variables.tf

variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "The base name for the EKS cluster and all related resources."
  type        = string
  default     = "code-2-cloud"
}

variable "instance_type" {
  description = "The EC2 instance type for the worker node."
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "The name of the SSH key pair to attach to the instance."
  type        = string
}

variable "vpc_cidr_block" {
  description = "The primary CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets to create. Key is the AZ suffix (e.g., 'a', 'b')."
  type = map(object({
    availability_zone_suffix = string
    cidr_block               = string
  }))
  default = {
    "1" = {
      availability_zone_suffix = "a"
      cidr_block               = "10.0.1.0/24"
    },
    "2" = {
      availability_zone_suffix = "b"
      cidr_block               = "10.0.2.0/24"
    }
  }
}

variable "private_subnets" {
  description = "Map of private subnets to create. Key is the AZ suffix (e.g., 'a', 'b')."
  type = map(object({
    availability_zone_suffix = string
    cidr_block               = string
  }))
  default = {
    "1" = {
      availability_zone_suffix = "a"
      cidr_block               = "10.0.3.0/24"
    },
    "2" = {
      availability_zone_suffix = "b"
      cidr_block               = "10.0.4.0/24"
    }
  }
}

variable "identity_store_id" {
  description = "The ID of the IAM Identity Center instance."
  type        = string
}

variable "lambda_code_bucket_name" {
  description = "The name of the S3 bucket to store Lambda function code."
  type        = string
}

variable "cloudtrail_logs_bucket_name" {
  description = "The name for the CloudTrail logs S3 bucket."
  type        = string
  default     = "cortex-cloudtrail-logs-980573775279-m-a-999593-unique"
}

variable "cf_templates_bucket_name" {
  description = "The name for the CloudFormation templates S3 bucket."
  type        = string
  default     = "cf-templates-i2c1kyakxlt-us-east-1-unique"
}

variable "cortex_custom_lambda_name_1" {
  description = "The exact name for the first Cortex custom Lambda function."
  type        = string
  default     = "qa2-test-9994491753254-CortexTemplateCustomLambdaF-3iOltL-unique"
}

variable "empty_bucket_lambda_name" {
  description = "The exact name for the Empty Bucket Lambda function."
  type        = string
  default     = "cortex-api-9995931061259-EmptyBucketLambda-xp4WazTxy5fp"
}

variable "cortex_custom_lambda_name_2" {
  description = "The exact name for the second Cortex custom Lambda function."
  type        = string
  default     = "cortex-api-9995931061259-CortexTemplateCustomLambd-D2KrVz-unique"
}