output "arn" {
	value = aws_lambda_layer_version.main.arn
	description = "The Amazon Resource Name (ARN) of the Lambda layer with version."
}

output "layer_arn" {
	value = aws_lambda_layer_version.main.layer_arn
	description = "The Amazon Resource Name (ARN) of the Lambda layer without version."
}

output "version" {
	value = aws_lambda_layer_version.main.version
	description = "The Lamba layer version."
}
