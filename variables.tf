variable "region" {
  description = "The regions in which the VPCs will be created"

  type = object(
    {
      vpn_vpc       = string
      libreswan_vpc = string
    }
  )

  default = {
    vpn_vpc       = "us-east-2"
    libreswan_vpc = "us-west-2"
  }
}

variable "cidr_block" {
  description = "The CIDR blocks of the VPCs"

  type = object(
    {
      vpn_vpc       = string
      libreswan_vpc = string
    }
  )

  default = {
    vpn_vpc       = null
    libreswan_vpc = null
  }
}
