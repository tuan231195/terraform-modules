module "aws_lambda_logs" {
	source = "../aws-lambda"
	runtime = "nodejs12.x"
	function_name = var.lambda_name
	policy = {
		json = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
		{
            "Effect": "Allow",
            "Action": "es:ESHttpPost",
            "Resource": "*"
        }
  ]
}
EOF
	}
	handler = "index.handler"
	source_path = "${path.module}/lambda/index.js"
	vpc_config = {
		subnet_ids = var.subnets
		security_group_ids = var.lambda_security_groups
	}
	tags = var.tags
	environment = {
		variables = {
			ELASTICSEARCH_ENDPOINT = var.elasticsearch_service_endpoint
		}
	}
}

resource "aws_cloudwatch_log_group" "cloudwatch_logs" {
	name = "/aws/lambda/${module.aws_lambda_logs.function_name}"
	retention_in_days = 14
	tags = var.tags
}

resource "aws_lambda_permission" "lambda_permission_allow_cloudwatch" {
	statement_id = "allow-cloudwatch"
	action = "lambda:InvokeFunction"
	function_name = module.aws_lambda_logs.function_name
	principal = "logs.ap-southeast-2.amazonaws.com"
	source_account = data.aws_caller_identity.current.account_id
	source_arn = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*:*"
}

resource "aws_cloudformation_stack" "logs" {
	name = module.aws_lambda_logs.function_name
	capabilities = [
		"CAPABILITY_AUTO_EXPAND",
		"CAPABILITY_NAMED_IAM"
	]
	template_body = <<EOF
AWSTemplateFormatVersion: 2010-09-09
Transform: AWS::Serverless-2016-10-31
Resources:
  SubscribeToElasticSearch:
    Type: AWS::Serverless::Application
    Properties:
      Location:
        ApplicationId: arn:aws:serverlessrepo:us-east-1:374852340823:applications/auto-subscribe-log-group-to-arn
        SemanticVersion: 1.11.1
      Parameters:
        DestinationArn: "${module.aws_lambda_logs.function_arn}"
        Prefix: "/aws/lambda/"
        ExcludePrefix: "/aws/lambda/logs-to-es"
EOF
}