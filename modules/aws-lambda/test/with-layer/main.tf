provider "aws" {
	region = "ap-southeast-2"
}

module "lambda" {
	source = "../../../aws-lambda"
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