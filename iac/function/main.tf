resource "aws_lambda_function" "worker" {
  function_name    = var.function_name
  filename         = data.archive_file.lambda_zip_file.output_path
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256
  handler          = "worker.handler"
  role             = aws_iam_role.lambda_iam_role.arn
  runtime          = "nodejs16.x"
  timeout          = 30
  environment {
    variables = {
      SNSPublishArns = jsonencode(var.publish_to_topics_uris)
      SNSSubscriptionArns = jsonencode(var.subscribe_to_topics_uris)
    }
  }
}

data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_file = "${var.source_dir}"
  output_path = "${var.output_zip}"
}

data "aws_iam_policy" "lambda_basic_execution_role_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_iam_role" {
  name_prefix         = "LambdaSNSRole-"
  managed_policy_arns = [
    data.aws_iam_policy.lambda_basic_execution_role_policy.arn,
    aws_iam_policy.lambda_policy.arn
  ]

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

locals {
  publish_arns = values(var.publish_to_topics_uris)
}

data "aws_iam_policy_document" "publish_lambda_policy_document" {
  statement {
  
    effect = "Allow"
  
    actions = [
      "sns:Publish"
    ]

    resources = local.publish_arns
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name_prefix = "lambda_policy-"
  path        = "/"
  policy      = data.aws_iam_policy_document.publish_lambda_policy_document.json
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region = data.aws_region.current.name
}

resource "aws_lambda_permission" "sns" {
  for_each = toset(keys(var.subscribe_to_topics_uris))
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:${local.region}:${local.account_id}:${each.key}"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  for_each = toset(keys(var.subscribe_to_topics_uris))
  topic_arn = "arn:aws:sns:${local.region}:${local.account_id}:${each.key}"
  protocol  = "lambda"
  endpoint  = aws_lambda_function.worker.arn
}