terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region.vpn_vpc

  default_tags {
    tags = { Name : "AWS VPN" }
  }
}

provider "aws" {
  region = var.region.libreswan_vpc
  alias  = "libreswan"

  default_tags {
    tags = { Name : "Libreswan" }
  }
}

resource "aws_eip" "vpn" {
  domain = "vpc"
}

resource "aws_eip" "libreswan" {
  domain = "vpc"

  provider = aws.libreswan
}

module "vpn_vpc" {
  source = "./modules/vpc"

  cidr_block      = var.cidr_block.vpn_vpc
  peer_cidr_block = var.cidr_block.libreswan_vpc
}

module "libreswan_vpc" {
  source = "./modules/vpc"

  cidr_block          = var.cidr_block.libreswan_vpc
  peer_cidr_block     = var.cidr_block.vpn_vpc
  vpn_tunnel1_address = aws_vpn_connection.this.tunnel1_address

  providers = {
    aws = aws.libreswan
  }
}

resource "aws_vpn_gateway" "this" {
  vpc_id = module.vpn_vpc.vpc_id
}

resource "aws_vpn_gateway_attachment" "this" {
  vpc_id         = module.vpn_vpc.vpc_id
  vpn_gateway_id = aws_vpn_gateway.this.id
}

resource "aws_customer_gateway" "this" {
  bgp_asn = 65000
  type    = "ipsec.1"

  ip_address  = aws_eip.libreswan.public_ip
  device_name = "Libreswan"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpn_connection" "this" {
  customer_gateway_id = aws_customer_gateway.this.id
  type                = "ipsec.1"

  vpn_gateway_id     = aws_vpn_gateway.this.id
  static_routes_only = true
}

resource "aws_vpn_gateway_route_propagation" "this" {
  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = module.vpn_vpc.default_route_table_id
}

resource "aws_vpn_connection_route" "this" {
  destination_cidr_block = var.cidr_block.libreswan_vpc
  vpn_connection_id      = aws_vpn_connection.this.id
}

resource "random_pet" "this" {
  provisioner "local-exec" {
    when    = create
    command = "ssh-keygen -q -P '' -f ${path.module}/${self.id}"
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "rm ${path.module}/${self.id} ${path.module}/${self.id}.pub"
    on_failure = continue
  }
}

resource "aws_key_pair" "vpn" {
  public_key = file(format("%s.pub", random_pet.this.id))
  key_name   = random_pet.this.id
}

resource "aws_key_pair" "libreswan" {
  public_key = file("${random_pet.this.id}.pub")
  key_name   = random_pet.this.id

  provider = aws.libreswan
}

data "cloudinit_config" "vpn" {
  gzip          = false
  base64_encode = false

  part {
    content = file("user-data-vpn.yaml")

    content_type = "text/cloud-config"
    filename     = "cloud-init.conf"
  }
}

module "vpn_instance" {
  source = "./modules/instance"

  user_data          = data.cloudinit_config.vpn.rendered
  eip_allocation_id  = aws_eip.vpn.id
  subnet_id          = module.vpn_vpc.subnet_id
  security_group_ids = [module.vpn_vpc.default_security_group_id]
  key_name           = aws_key_pair.vpn.key_name
}

data "cloudinit_config" "libreswan" {
  gzip          = false
  base64_encode = false

  part {
    content = templatefile(
      "user-data-libreswan.yaml",
      {
        libreswan_ip : aws_eip.libreswan.public_ip,
        vpn_ip : aws_vpn_connection.this.tunnel1_address,
        libreswan_cidr_block : var.cidr_block.libreswan_vpc,
        vpn_cidr_block : var.cidr_block.vpn_vpc,
        psk : aws_vpn_connection.this.tunnel1_preshared_key,
      }
    )

    content_type = "text/jinja2"
    filename     = "cloud-init.conf"
  }
}

module "libreswan_instance" {
  source = "./modules/instance"

  user_data          = data.cloudinit_config.libreswan.rendered
  eip_allocation_id  = aws_eip.libreswan.id
  subnet_id          = module.libreswan_vpc.subnet_id
  security_group_ids = [module.libreswan_vpc.default_security_group_id]
  key_name           = aws_key_pair.libreswan.key_name

  providers = {
    aws = aws.libreswan
  }
}
