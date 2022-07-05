module "gabriel08-app" {
  source = "./modules/gabriel08-app"
  cidr_block = "10.0.100.0/24"
  vpc_name = "gabriel-08"
  project = "gabriel-08-module"
  env = "qa"
  create_zone_dns = false
}

output "ip_app" {
  value = module.gabriel08-app.app_public_ip
}

variable "cidr_block" {
  type = string
  default = "10.0.100.0/24"
}

variable "env" {
  type = string
  default = "env"
}
