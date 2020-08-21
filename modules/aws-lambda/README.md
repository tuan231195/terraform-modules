# terraform-aws-lambda

This Terraform module creates and uploads an AWS Lambda function and hides the ugly parts from you.

## Features

* Only appears in the Terraform plan when there are legitimate changes.
* Zips up a source file or directory.

## Requirements

* Python 2.7 or higher
* Linux/Unix/Windows

## Usage

```js
module "lambda" {
  source = "github.com/claranet/terraform-aws-lambda"

  function_name = "deployment-deploy-status"
  description   = "Deployment deploy status task"
  handler       = "main.lambda_handler"
  runtime       = "python3.6"
  timeout       = 300

  // Specify a file or directory for the source code.
  source_path = "${path.module}/lambda.py"

  // Add additional trusted entities for assuming roles (trust relationships).
  trusted_entities = ["events.amazonaws.com", "s3.amazonaws.com"]

  // Attach a policy.
  policy = {
    json = data.aws_iam_policy_document.lambda.json
  }

  // Add a dead letter queue.
  dead_letter_config = {
    target_arn = aws_sqs_queue.dlq.arn
  }

  // Add environment variables.
  environment = {
    variables = {
      SLACK_URL = var.slack_url
    }
  }

  // Deploy into a VPC.
  vpc_config = {
    subnet_ids         = [aws_subnet.test.id]
    security_group_ids = [aws_security_group.test.id]
  }
}
```

## Inputs

Inputs for this module are the same as the [aws_lambda_function](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) resource with the following additional arguments:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| **source\_path** | The absolute path to a local file or directory containing your Lambda source code | `string` | | yes |
| rsync_patterns | A list of rsync pattern to include or exclude files and directories. | `bool` | `true` | no |
| cloudwatch\_logs | Set this to false to disable logging your Lambda output to CloudWatch Logs | `bool` | `true` | no |
| lambda\_at\_edge | Set this to true if using Lambda@Edge, to enable publishing, limit the timeout, and allow edgelambda.amazonaws.com to invoke the function | `bool` | `false` | no |
| policy | An additional policy to attach to the Lambda function role | `object({json=string})` | | no |
| trusted\_entities | Additional trusted entities for the Lambda function. The lambda.amazonaws.com (and edgelambda.amazonaws.com if lambda\_at\_edge is true) is always set  | `list(string)` | | no |

The following arguments from the [aws_lambda_function](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) resource are not supported:

* filename (use source\_path instead)
* s3_bucket
* s3_key
* s3_object_version
* source_code_hash (changes are handled automatically)

## Outputs

| Name | Description |
|------|-------------|
| function\_arn | The ARN of the Lambda function |
| function\_invoke\_arn | The Invoke ARN of the Lambda function |
| function\_name | The name of the Lambda function |
| function\_qualified\_arn | The qualified ARN of the Lambda function |
| role\_arn | The ARN of the IAM role created for the Lambda function |
