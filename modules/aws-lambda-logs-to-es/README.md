# aws-lambda

This Terraform module automatically subscribes all cloudwatch to elasticsearch


## Requirements

* Python 3.6 or higher
* Linux/Unix/Windows

## Usage

```js
module "logs-to-es" {
	source = "git::https://github.com/tuan231195/terraform-modules.git//modules/aws-lambda-logs-to-es?ref=master"
	elasticsearch_service_endpoint = aws_elasticsearch_domain.es.endpoint
	lambda_name = "logs-to-es"
	subnets = [
		module.vpc.private_subnets[0]
	]
	lambda_security_groups = [
		module.vpc.default_security_group_id
	]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| **elasticsearch\_service\_endpoint** | The elasticsearch service endpoint | `string` |  | yes |
| **lambda_security_groups** | The lambda security group ids | `list(string)` |  | yes |
| **subnets** | The private subnets that the lambda is in  | `list(string)` |  | yes |
| lambda\_name | The name of the lambda function | `string` | `logs-to-es` | no |

## Outputs

| Name | Description |
|------|-------------|
| lambda\_function\_arn | The ARN of the Logs function |