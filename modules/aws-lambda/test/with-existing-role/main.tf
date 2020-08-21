provider "aws" {
	region = "ap-southeast-2"
}

module "lambda" {
	source = "../../../aws-lambda"
	function_name = "test-existing-role"
	handler = "index.handler"
	source_path = "${path.module}/build"
	iam_role = {
		arn = aws_iam_role.lambda_role.arn
	}
	runtime = "nodejs12.x"
}

data "aws_iam_policy_document" "lambda_assume_role" {
	statement {
		effect = "Allow"
		actions = [
			"sts:AssumeRole"
		]

		principals {
			type = "Service"
			identifiers = [
				"lambda.amazonaws.com"
			]
		}
	}
}

data "aws_iam_policy" "vpc_access_policy" {
	arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access_policy_attachment" {
	role = aws_iam_role.lambda_role.id
	policy_arn = data.aws_iam_policy.vpc_access_policy.arn
}

resource "aws_iam_role_policy" "lambda_policy" {
	name = "lambda-policy"
	role = aws_iam_role.lambda_role.id

	policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
		{
		      "Action": [
		        "lambda:ListTags"
		      ],
		      "Resource": "*",
		      "Effect": "Allow"
        }
  ]
}
EOF
}


data "aws_iam_policy" "lambda_basic_execution_policy" {
	arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_policy_attachment" {
	role = aws_iam_role.lambda_role.id
	policy_arn = data.aws_iam_policy.lambda_basic_execution_policy.arn
}

resource "aws_iam_role" "lambda_role" {
	name = "test-lambda-role"
	assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
