variable "elasticsearch_service_endpoint" {}

variable "subnets" {}

variable "lambda_security_groups" {}

variable "tags" {
	type = map(string)
	default = {}
}

variable "lambda_name" {
	type = string
	default = "logs-to-es"
}
