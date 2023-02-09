variable "vpc_id" {
  description = "The VPC ID in AWS"
}

variable "name" {
  description = "Name to be used for the Tags"
}

variable "route_table_id" {
  description = "ID for the Route Table in AWS"
}

variable "cidr_block" {
  description = "The CIDR block of the tier subnet"
}

variable "user_data" {
  description = "Template path for the user template"
}

variable "ami_id" {
  description = "ID for AMI in AWS"
}

variable "map_public_ip_on_launch" {
  default = false
  description = "Boolean for setting public IP on launch"
}

variable "ingress" {
  type = list
  description = "Sets the access to the network, port, and the protocol"
}

variable "region" {
  type = string
}
