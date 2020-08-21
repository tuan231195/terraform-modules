provider "aws" {
	region = "ap-southeast-2"
}

module "lambda" {
	source = "../../../aws-lambda"
	function_name = "test-function-with-layer-built"
	handler = "index.handler"
	source_path = "${path.module}/build"
	rsync_pattern = [
		"--exclude 'node_modules'"
	]
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
		source_type = "nodejs"
		source_dir = "${path.module}/build"
		rsync_patterns = [
			"--exclude 'node_modules/.bin'",
			"--include='node_modules/***'",
			"--exclude='*'",
		]
		compatible_runtimes = ["nodejs12.x"]
	}
}