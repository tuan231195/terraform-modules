output "es_endpoint" {
	value = aws_elasticsearch_domain.es.endpoint
}

output "kibana_endpoint" {
	value = aws_elasticsearch_domain.es.kibana_endpoint
}

output "bastion_host_ip" {
	value = aws_instance.bastion_host.public_ip
}