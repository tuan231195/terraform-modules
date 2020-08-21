resource "aws_lambda_function" "lambda" {
	function_name = var.function_name
	description = var.description
	role = var.iam_role != null ? var.iam_role.arn : try(aws_iam_role.lambda[0].arn, null)
	handler = var.handler
	memory_size = var.memory_size
	reserved_concurrent_executions = var.reserved_concurrent_executions
	runtime = var.runtime
	layers = concat(var.layers, var.layer_config != null ? list(module.lambda_layer[0].arn) : [])
	timeout = local.timeout
	publish = local.publish
	tags = var.tags

	filename = lookup(data.external.build.result, "output_file")
	source_code_hash = lookup(data.external.build.result, "output_hash")

	# Add dynamic blocks based on variables.

	dynamic "dead_letter_config" {
		for_each = var.dead_letter_config == null ? [] : [
			var.dead_letter_config]
		content {
			target_arn = dead_letter_config.value.target_arn
		}
	}

	dynamic "environment" {
		for_each = var.environment == null ? [] : [
			var.environment]
		content {
			variables = environment.value.variables
		}
	}

	dynamic "tracing_config" {
		for_each = var.tracing_config == null ? [] : [
			var.tracing_config]
		content {
			mode = tracing_config.value.mode
		}
	}

	dynamic "vpc_config" {
		for_each = var.vpc_config == null ? [] : [
			var.vpc_config]
		content {
			security_group_ids = vpc_config.value.security_group_ids
			subnet_ids = vpc_config.value.subnet_ids
		}
	}
}

module "lambda_layer" {
	count = var.layer_config != null ? 1 : 0
	source = "../aws-lambda-layer"
	layer_name = lookup(var.layer_config, "layer_name", "${var.function_name}-layer")
	description = lookup(var.layer_config, "description", "")
	package_file = lookup(var.layer_config, "package_file", null)
	compatible_runtimes = lookup(var.layer_config, "compatible_runtimes")
	source_dir = lookup(var.layer_config, "source_dir", null)
	source_type = lookup(var.layer_config, "source_type", null)
	rsync_pattern = lookup(var.layer_config, "rsync_pattern", ["--include=*"])
}
