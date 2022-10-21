provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      bot-tg-yt = "aws-asg"
    }
  }
}

######################################################################

resource "aws_s3_bucket" "data_bucket" {
  bucket = "lambda-calc-2110"

  tags = {
    Name        = "lambda-calc-3009"
  }
}


######################################################################

resource "aws_iam_role" "lambda_role" {
name   = "lambda_function_assume_role"
assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": [
                    "apigateway.amazonaws.com",
                    "lambda.amazonaws.com"
                ]
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

######################################################################

resource "aws_iam_policy" "iam_policy_for_lambda" {
 
 name         = "aws_iam_policy_for_terraform_aws_lambda_role"
 path         = "/"
 description  = "AWS IAM Policy for managing aws lambda role"
 policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": "*"
        },
        {
            "Action": [
                "sns:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
})
}

######################################################################

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

######################################################################

data "archive_file" "zip_the_python_code" {
type        = "zip"
source_dir  = "${path.module}/python/"
output_path = "${path.module}/python/python.zip"
}

######################################################################

resource "aws_lambda_function" "terraform_lambda_func" {
filename          = "${path.module}/python/python.zip"
function_name     = "calc-3009"
role              = aws_iam_role.lambda_role.arn
handler           = "index.lambda_handler"
runtime           = "python3.9"
depends_on        = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

######################################################################

resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowAPIgatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.function_name
  principal     = "apigateway.amazonaws.com"
}

######################################################################

resource "aws_sns_topic" "topic" {
  name = "topic-calc"
}
######################################################################

locals {
  emails = ["nati.malkiel@gmail.com", "tomerl@cloudbuzz.co.il"]
}

resource "aws_sns_topic_subscription" "email-target" {
  count     = length(local.emails)
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = local.emails[count.index]
}

######################################################################

resource "aws_api_gateway_rest_api" "calcAPI" {
  name        = "MyDemoAPI"
  description = "This is my API for demonstration purposes"
}

######################################################################

resource "aws_api_gateway_resource" "Resource" {
  rest_api_id = aws_api_gateway_rest_api.calcAPI.id
  parent_id   = aws_api_gateway_rest_api.calcAPI.root_resource_id
  path_part   = "mydemoresource"
}

######################################################################

resource "aws_api_gateway_method" "Method" {
  rest_api_id   = aws_api_gateway_rest_api.calcAPI.id
  resource_id   = aws_api_gateway_resource.Resource.id
  http_method   = "GET"
  authorization = "NONE"
}

######################################################################

resource "aws_api_gateway_integration" "Integration" {
  rest_api_id          = aws_api_gateway_rest_api.calcAPI.id
  resource_id          = aws_api_gateway_resource.Resource.id
  http_method          = aws_api_gateway_method.Method.http_method
  type                 = "MOCK"
}

######################################################################

resource "aws_api_gateway_deployment" "example" {
  depends_on = [aws_api_gateway_integration.Integration]

  rest_api_id = aws_api_gateway_rest_api.calcAPI.id
  stage_name  = "test"

  variables = {
    "answer" = "42"
  }

  lifecycle {
    create_before_destroy = true
  }
}