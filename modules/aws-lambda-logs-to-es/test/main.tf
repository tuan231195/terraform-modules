provider "aws" {
	region = "ap-southeast-2"
}

locals {
	es_domain = "test-es"
	myip_cidr = "${chomp(data.http.myip.body)}/32"
}

module "vpc" {
	source = "terraform-aws-modules/vpc/aws"

	name = "test-vpc"
	cidr = "10.0.0.0/16"

	azs = [
		"ap-southeast-2a",
		"ap-southeast-2b",
		"ap-southeast-2c"
	]

	private_subnets = [
		"10.0.1.0/24"
	]

	public_subnets = [
		"10.0.101.0/24"
	]

	enable_nat_gateway = false
	enable_vpn_gateway = false
}

data "http" "myip" {
	url = "http://ipv4.icanhazip.com"
}

resource "aws_iam_service_linked_role" "es_linked_role" {
	aws_service_name = "es.amazonaws.com"
}

resource "aws_elasticsearch_domain" "es" {
	depends_on = [
		aws_iam_service_linked_role.es_linked_role]
	domain_name = local.es_domain
	elasticsearch_version = "7.7"

	cluster_config {
		instance_type = "t2.small.elasticsearch"
	}

	vpc_options {
		subnet_ids = [
			module.vpc.private_subnets[0]
		]
		security_group_ids = [
			aws_security_group.es_sg.id
		]
	}

	ebs_options {
		ebs_enabled = true
		volume_size = 10
	}

	access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "es:*",
          "Principal": "*",
          "Effect": "Allow",
          "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current
.account_id}:domain/${local.es_domain}/*"
      }
  ]
}
  CONFIG

	tags = {
		Domain = local.es_domain
	}
}

resource "aws_security_group" "es_sg" {
	name = "${local.es_domain}-sg"
	description = "Allow inbound traffic to ElasticSearch from VPC CIDR"
	vpc_id = module.vpc.vpc_id

	ingress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = [
			module.vpc.vpc_cidr_block
		]
	}
}

module "logs_to_elasticsearch" {
	source = "../"
	elasticsearch_service_endpoint = aws_elasticsearch_domain.es.endpoint
	lambda_name = "logs-to-es"
	subnets = [
		module.vpc.private_subnets[0]
	]
	lambda_security_groups = [
		module.vpc.default_security_group_id
	]
}

resource "aws_security_group" "bastion_host_sg" {
	name = "bastion-host-sg"
	vpc_id = module.vpc.vpc_id
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = [
			"0.0.0.0/0"
		]
	}

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = [
			local.myip_cidr
		]
	}

	ingress {
		from_port = 9200
		to_port = 9200
		protocol = "tcp"
		cidr_blocks = [
			local.myip_cidr
		]
	}

	egress {
		from_port = 0
		protocol = "-1"
		to_port = 0
		cidr_blocks = [
			"0.0.0.0/0"
		]
	}
}

resource "aws_key_pair" "ec2_key_pair" {
	public_key = file("~/.ssh/id_rsa.pub")
	key_name = "ec2-key"
}

resource "aws_instance" "bastion_host" {
	ami = "ami-01b1940e02781a0fb"
	instance_type = "t2.micro"
	vpc_security_group_ids = [
		aws_security_group.bastion_host_sg.id
	]
	key_name = aws_key_pair.ec2_key_pair.key_name
	associate_public_ip_address = true
	subnet_id = module.vpc.public_subnets[0]
}

resource "null_resource" "sync_nginx" {
	triggers = {
		always = timestamp()
	}

	connection {
		type = "ssh"
		host = aws_instance.bastion_host.public_ip
		user = "ubuntu"
		private_key = file("~/.ssh/id_rsa")
	}

	provisioner "file" {
		destination = "/etc/nginx/conf.d/es.conf"
		content = data.template_file.es.rendered
	}

	provisioner "remote-exec" {
		inline = [
			"sudo nginx -s reload"
		]
	}
}

data "template_file" "es" {
	template = file("${path.module}/config/es.tpl")
	vars = {
		es_endpoint = aws_elasticsearch_domain.es.endpoint
	}
}