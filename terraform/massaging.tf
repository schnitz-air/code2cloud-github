# messaging.tf

# Defines the SNS (Simple Notification Service) Topic that will receive notifications.
resource "aws_sns_topic" "cloudtrail_notifications" {
  name = "cortex-cloudtrail-logs-notification-980573775279-m-a-9995931061259"

  tags = {
    "managed_by" = "paloaltonetworks"
    yor_trace    = "5ace4cb8-7329-46fe-8d46-a0df687e02b2"
  }
}

# Attaches a resource-based policy to the SNS topic.
# This specific policy allows the AWS CloudTrail service to publish messages.
resource "aws_sns_topic_policy" "cloudtrail_notifications_policy" {
  arn = aws_sns_topic.cloudtrail_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudTrailPublish",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "sns:Publish",
        Resource  = aws_sns_topic.cloudtrail_notifications.arn
      }
    ]
  })
}

# Defines the default delivery retry policy for HTTP/S subscribers to the topic.
resource "aws_sns_topic_delivery_policy" "cloudtrail_notifications_delivery_policy" {
  arn = aws_sns_topic.cloudtrail_notifications.arn

  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20,
        maxDelayTarget     = 20,
        numRetries         = 3,
        numMaxDelayRetries = 0,
        numNoDelayRetries  = 0,
        numMinDelayRetries = 0,
        backoffFunction    = "linear"
      }
    }
  })
}

# Defines the SQS (Simple Queue Service) Queue that will receive and store messages.
resource "aws_sqs_queue" "cloudtrail_queue" {
  name = "cortex-cloudtrail-logs-queue-980573775279-m-a-9995931061259"

  delay_seconds              = 0
  max_message_size           = 1048576
  message_retention_seconds  = 345600
  visibility_timeout_seconds = 30
  sqs_managed_sse_enabled    = true

  tags = {
    "managed_by" = "paloaltonetworks"
    yor_trace    = "da138900-c796-44a4-8007-6397c2d8bd06"
  }
}

# A data source used to dynamically build the SQS queue's access policy.
data "aws_iam_policy_document" "sqs_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["SQS:SendMessage"]
    resources = [aws_sqs_queue.cloudtrail_queue.arn]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.cloudtrail_notifications.arn]
    }
  }
}

# Attaches the resource-based policy to the SQS queue.
# This policy allows the specific SNS topic to send messages to this queue.
resource "aws_sqs_queue_policy" "cloudtrail_queue_policy" {
  queue_url = aws_sqs_queue.cloudtrail_queue.id
  policy    = data.aws_iam_policy_document.sqs_policy_doc.json
}

# Creates the subscription that links the SNS topic to the SQS queue.
# This is the final piece that makes messages flow from the topic to the queue.
resource "aws_sns_topic_subscription" "cloudtrail_to_sqs" {
  topic_arn = aws_sns_topic.cloudtrail_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.cloudtrail_queue.arn
}