output "vpc_id" {
  value = aws_vpc.this.id
}

output "cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "default_route_table_id" {
  value = aws_vpc.this.default_route_table_id
}

output "default_security_group_id" {
  value = aws_vpc.this.default_security_group_id
}

output "subnet_id" {
  value = aws_subnet.this.id
}
