resource "aws_lambda_layer_version" "main" {
	filename = lookup(data.external.build.result, "output_file")
	layer_name = var.layer_name
	source_code_hash = lookup(data.external.build.result, "output_hash")
	compatible_runtimes = var.compatible_runtimes
	description = var.description
}
