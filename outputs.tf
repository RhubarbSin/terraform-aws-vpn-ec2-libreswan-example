output "vpn_instance_public_ip" {
  value = aws_eip.vpn.public_ip

  description = "The public IP address of the EC2 instance in the AWS VPN VPC"
}

output "vpn_instance_private_ip" {
  value = module.vpn_instance.private_ip

  description = "The private IP address of the EC2 instance in the AWS VPN VPC"
}

output "libreswan_instance_public_ip" {
  value = aws_eip.libreswan.public_ip

  description = "The public IP address of the EC2 instance in the Libreswan VPC"
}

output "libreswan_instance_private_ip" {
  value = module.libreswan_instance.private_ip

  description = "The private IP address of the EC2 instance in the Libreswan VPC"
}

output "ssh_key_file_name" {
  value = basename(local_sensitive_file.this.filename)

  description = "The name of the file that contains the private SSH key used by the EC2 instances"
}

output "vpn_region" {
  value = var.region.vpn_vpc

  description = "The region in which the AWS VPN resides"
}

output "vpn_connection_id" {
  value = aws_vpn_connection.this.id

  description = "The ID of the AWS VPN"
}
