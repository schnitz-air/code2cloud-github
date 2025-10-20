# s3.tf

# --------------------------------------------------------------
# S3 Bucket for CloudTrail Logs
# --------------------------------------------------------------

# Defines the primary S3 bucket resource for storing CloudTrail logs.
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = var.cloudtrail_logs_bucket_name
  tags = { "managed_by" = "paloaltonetworks"
    yor_trace = "6df7191d-c4d1-4e05-9690-4784798fd344"
  }
}

# Enforces settings to block all public access to the CloudTrail logs bucket.
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs_pab" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configures S3 object ownership, disabling ACLs for simplified permissions management.
resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs_oc" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Enables default server-side encryption for all new objects using a specific KMS key.
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs_sse" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Defines a lifecycle rule to automatically delete objects from the bucket after 7 days.
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs_lifecycle" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    id     = "DeleteOldLogs"
    status = "Enabled"
    expiration {
      days = 7
    }
    filter {}
  }
}

# Attaches a resource-based policy to allow the CloudTrail service to write logs to the bucket.
resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudTrailWrite1",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/*",
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      },
      {
        Sid       = "AllowCloudTrailACL1",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      }
    ]
  })
}


# --------------------------------------------------------------
# S3 Bucket for CloudFormation Templates
# --------------------------------------------------------------

# Defines the S3 bucket used for storing CloudFormation templates.
resource "aws_s3_bucket" "cf_templates" {
  bucket = var.cf_templates_bucket_name
  tags = {
    yor_trace = "153adb36-af2f-44fe-ab87-21c23ec927da"
  }
}

# Blocks all public access to the CloudFormation templates bucket.
resource "aws_s3_bucket_public_access_block" "cf_templates_pab" {
  bucket                  = aws_s3_bucket.cf_templates.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disables ACLs for simplified permissions.
resource "aws_s3_bucket_ownership_controls" "cf_templates_oc" {
  bucket = aws_s3_bucket.cf_templates.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Enables default server-side encryption using the standard AES256 algorithm.
resource "aws_s3_bucket_server_side_encryption_configuration" "cf_templates_sse" {
  bucket = aws_s3_bucket.cf_templates.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# --------------------------------------------------------------
# S3 Bucket for Cortex Testing
# --------------------------------------------------------------

# Defines the S3 bucket for Cortex testing purposes.
resource "aws_s3_bucket" "c2c_test_cortex" {
  bucket = "c2c-test-cortex"
  tags = {
    yor_trace = "a04ae2fb-0741-479b-95d3-cf49fcd906f8"
  }
}

# Blocks all public access to the Cortex test bucket.
resource "aws_s3_bucket_public_access_block" "c2c_test_cortex_pab" {
  bucket                  = aws_s3_bucket.c2c_test_cortex.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Disables ACLs for simplified permissions.
resource "aws_s3_bucket_ownership_controls" "c2c_test_cortex_oc" {
  bucket = aws_s3_bucket.c2c_test_cortex.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Enables default AES256 encryption with an S3 Bucket Key for KMS cost savings.
resource "aws_s3_bucket_server_side_encryption_configuration" "c2c_test_cortex_sse" {
  bucket = aws_s3_bucket.c2c_test_cortex.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}