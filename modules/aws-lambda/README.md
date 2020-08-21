# aws-lambda

This Terraform module creates and uploads an AWS Lambda function and hides the ugly parts from you. This is a modified version of https://github.com/claranet/terraform-aws-lambda

## Features

* Only appears in the Terraform plan when there are legitimate changes.
* Zips up a source file or directory.
* Support building layers


## Requirements

* Python 3.6 or higher
* Linux/Unix/Windows

## Usage

```js
module "lambda" {
	source = "git::https://github.com/tuan231195/terraform-modules.git//modules/aws-lambda?ref=master"
	function_name = "test-function-with-layer"
	handler = "index.handler"
	source_path = "${path.module}/build"
	runtime = "nodejs12.x"
		policy = {
		json = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [
            "secretsmanager:*"
        ],
        "Resource": "*",
        "Effect": "Allow"
    }
  ]
}
EOF
	}
	layer_config = {
		package_file = "${path.module}/build/package.json"
		compatible_runtimes = ["nodejs12.x"]
	}
}
```

## Inputs

Inputs for this module are the same as the [aws_lambda_function](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) resource with the following additional arguments:

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| **source\_path** | The absolute path to a local file or directory containing your Lambda source code | `string` | | yes |
| rsync_pattern | A list of rsync pattern to include or exclude files and directories. | `bool` | `true` | no |
| cloudwatch\_logs | Set this to false to disable logging your Lambda output to CloudWatch Logs | `bool` | `true` | no |
| lambda\_at\_edge | Set this to true if using Lambda@Edge, to enable publishing, limit the timeout, and allow edgelambda.amazonaws.com to invoke the function | `bool` | `false` | no |
| policy | An additional policy to attach to the Lambda function role | `object({json=string})` | | no |
| trusted\_entities | Additional trusted entities for the Lambda function. The lambda.amazonaws.com (and edgelambda.amazonaws.com if lambda\_at\_edge is true) is always set  | `list(string)` | | no |
| iam_role | A predefined iam role to use for the lambda  | `object({ arn: string })` | | no |

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
