# Create the role.

data "aws_iam_policy_document" "assume_role" {
	statement {
		effect = "Allow"
		actions = [
			"sts:AssumeRole"
		]

		principals {
			type = "Service"
			identifiers = concat(slice(list("lambda.amazonaws.com", "edgelambda.amazonaws.com"), 0, var.lambda_at_edge ? 2 : 1), var.trusted_entities)
		}
	}
}

resource "aws_iam_role" "lambda" {
	count = var.use_predefined_role ? 0 : 1
	name = var.function_name
	assume_role_policy = data.aws_iam_policy_document.assume_role.json
	tags = var.tags
}

# Attach a policy for logs.

locals {
	lambda_log_group_arn = "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.function_name}"
	lambda_edge_log_group_arn = "arn:${data.aws_partition.current.partition}:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/us-east-1.${var.function_name}"
	log_group_arns = slice(list(local.lambda_log_group_arn, local.lambda_edge_log_group_arn), 0, var.lambda_at_edge ? 2 : 1)
}

data "aws_iam_policy_document" "logs" {
	statement {
		effect = "Allow"

		actions = [
			"logs:CreateLogGroup",
		]

		resources = [
			"*",
		]
	}

	statement {
		effect = "Allow"

		actions = [
			"logs:CreateLogStream",
			"logs:PutLogEvents",
		]

		resources = concat(formatlist("%v:*", local.log_group_arns), formatlist("%v:*:*", local.log_group_arns))
	}
}

resource "aws_iam_role_policy" "logs" {
	count = var.cloudwatch_logs && !var.use_predefined_role ? 1 : 0

	name = "${var.function_name}-logs"
	policy = data.aws_iam_policy_document.logs.json
	role = aws_iam_role.lambda[0].id
}

data "aws_iam_policy_document" "dead_letter" {
	count = var.dead_letter_config != null ? 1 : 0
	statement {
		effect = "Allow"

		actions = [
			"sns:Publish",
			"sqs:SendMessage",
		]

		resources = [
			var.dead_letter_config.target_arn,
		]
	}
}

resource "aws_iam_role_policy" "dead_letter" {
	count = var.dead_letter_config == null || var.use_predefined_role ? 0 : 1
	name = "${var.function_name}-dl"
	role = aws_iam_role.lambda[0].id
	policy = data.aws_iam_policy_document.dead_letter[0].json
}

data "aws_iam_policy_document" "network" {
	statement {
		effect = "Allow"

		actions = [
			"ec2:CreateNetworkInterface",
			"ec2:DescribeNetworkInterfaces",
			"ec2:DeleteNetworkInterface",
		]

		resources = [
			"*",
		]
	}
}

resource "aws_iam_role_policy" "network" {
	count = var.vpc_config == null || var.use_predefined_role ? 0 : 1
	role = aws_iam_role.lambda[0].id
	name = "${var.function_name}-network"
	policy = data.aws_iam_policy_document.network.json
}

resource "aws_iam_role_policy" "additional" {
	count = var.policy == null || var.use_predefined_role ? 0 : 1

	name = var.function_name
	policy = var.policy.json
	role = aws_iam_role.lambda[0].id
}