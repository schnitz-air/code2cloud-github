# data_services.tf

# Configures the account-wide encryption settings for the AWS Glue Data Catalog.
resource "aws_glue_data_catalog_encryption_settings" "glue_settings" {
  data_catalog_encryption_settings {
    # Configures encryption for the metadata (table definitions, etc.) at rest.
    encryption_at_rest {
      catalog_encryption_mode = "SSE-KMS"

      # Reference the KMS key from your security.tf file.
      sse_aws_kms_key_id = aws_kms_key.cloudtrail_key.arn
    }

    # Configures encryption for passwords used in data source connections.
    connection_password_encryption {
      return_connection_password_encrypted = true

      # You can use the same KMS key for password encryption.
      aws_kms_key_id = aws_kms_key.cloudtrail_key.arn
    }
  }
}