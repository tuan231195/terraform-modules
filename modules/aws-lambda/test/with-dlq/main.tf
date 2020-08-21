provider "aws" {
  region = "ap-southeast-2"
}

resource "random_id" "name" {
  byte_length = 6
  prefix      = "terraform-aws-lambda-dlq-"
}

resource "aws_sqs_queue" "dlq" {
  name = random_id.name.hex
}

module "lambda" {
  source = "../../../aws-lambda"

  function_name = random_id.name.hex
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  timeout       = 30

  source_path = "${path.module}/build"

  dead_letter_config = {
    target_arn = aws_sqs_queue.dlq.arn
  }
}
