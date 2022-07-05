variable "project" {
  type    = string
  default = "coxinha"
}

variable "cidr_block" {
  type = string
}

variable "instance_type_app" {
  type = map
  default = {
    default = "t2.micro"
    dev     = "t2.micro"
    qa      = "t2.medium"
    prod    = "t3.medium"
  }
}

variable "instance_count" {
  type = map
  default = {
    default = "1"
    dev     = "2"
    qa      = "3"
    prod    = "4"
  }
}

variable "mongodb_version" {
  type = string
  default = "5.0.2"
}

variable "ec2-app" {
  type = map
  default = {
    version = "1.1.0"
    port = "8000"
    image = "skacko-api"
  }
}

variable "instance_type_mongodb" {
  type    = string
  default = "t2.small"
}

variable "vpc_name" {
  type    = string
}

variable "create_zone_dns" {
  type = bool
  default = false
}

variable "env" {
  type = string
  default = "dev"
}