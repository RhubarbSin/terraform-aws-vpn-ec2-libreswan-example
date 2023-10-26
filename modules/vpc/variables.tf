variable "cidr_block" {
  type = string
}

variable "peer_cidr_block" {
  type = string
}

variable "vpn_tunnel1_address" {
  type    = string
  default = null
}
