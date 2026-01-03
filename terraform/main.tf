provider "aws" {
  region = "eu-west-2"
}

# DynamoDB Table
resource "aws_dynamodb_table" "app_table" {
  name         = "incident-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# SNS Topic
resource "aws_sns_topic" "alert_topic" {
  name = "incident-alerts"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policy to Lambda role
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-incident-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.app_table.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.alert_topic.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "app" {
  function_name = "incident-api"
  runtime       = "python3.11"
  handler       = "app.handler"
  role          = aws_iam_role.lambda_role.arn

  filename         = "../lambda/app.zip"
  source_code_hash = filebase64sha256("../lambda/app.zip")

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.app_table.name
      SNS_TOPIC_ARN  = aws_sns_topic.alert_topic.arn
    }
  }
}

# API Gateway (Optional)
resource "aws_api_gateway_rest_api" "api" {
  name        = "incident-api"
  description = "Incident response API"
}

resource "aws_api_gateway_resource" "incident" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "incident"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.incident.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.incident.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.app.invoke_arn
}

# Deploy API
resource "aws_api_gateway_deployment" "api_deploy" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
}
