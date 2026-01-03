provider "aws" {
  region = "eu-west-2"
}

resource "aws_dynamodb_table" "app_table" {
  name         = "incident-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda-incident-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
#      {
 #       Action = [
  #        "dynamodb:PutItem"
   #     ]
    #    Effect   = "Allow"
     #   Resource = aws_dynamodb_table.app_table.arn
      #},   # <-- COMMA IS REQUIRED HERE
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "app" {
  function_name = "incident-api"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.handler"

  filename         = "../lambda/app.zip"
  source_code_hash = filebase64sha256("../lambda/app.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.app_table.name
    }
  }
}
