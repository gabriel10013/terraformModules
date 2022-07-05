resource "aws_key_pair" "app-ssh-key" {
  key_name   = "app-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDjo095soMwPZadZHFNzbCMJlA04rPI61d0yL27udSRvCBEgdLH0IbgrwX6XsJGwCG2yLtv+h7rhCSSVAYeBhwClW88Mk1gXJwbxBv5uH5SuydUAaoyvzMk0jiCFzwDAMBEEbYqAg3DO6p5/hwMFSHiTpSh6oQFY00nOWh622GW0tEdJqCb5dYhHuP19NIDJbYtPxFUE0QTWRtn0C2ZR3CudgxNElSpOsRLuDoh05ZX3FDXzmuj3FUIEs32eTgxFJx8rgXiDkqdasXOYW1r5ASLfRFPs9Iwute79a/9HFgUoKbCsaoA56YzbCHEIEc6VHlcbkGNyzF7+frSGySZhIup app-turma08"
}

resource "aws_instance" "app-ec2" {
  count                       = lookup(var.instance_count, var.env)
  ami                         = data.aws_ami.amazon-lnx.id
  instance_type               = lookup(var.instance_type_app, var.env)
  subnet_id                   = data.aws_subnet.app-public-subnet.id
  associate_public_ip_address = true
  tags = {
    Name = format("%s-app", local.name)
  }
  key_name  = aws_key_pair.app-ssh-key.id
  user_data = data.template_file.ec2-mongodb.rendered
}

resource "aws_instance" "app-mongodb" {
  ami                         = data.aws_ami.amazon-lnx.id
  instance_type               = var.instance_type_mongodb
  subnet_id                   = data.aws_subnet.app-public-subnet.id
  associate_public_ip_address = false
  tags = {
    Name = format("%s-mongodb", local.name)
  }
  key_name  = aws_key_pair.app-ssh-key.id
  user_data = data.template_file.ec2-mongodb.rendered
}

resource "aws_security_group" "allow-ssh" {
  name        = format("%s-allowsshandhttps", local.name)
  description = "Allow connections SSH and http ports"
  vpc_id      = data.aws_vpc.vpc.id

  ingress = [
    {
      description      = "Allow ssh"
      from_port        = "22"
      to_port          = "22"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = null
    },
    {
      description      = "Allow http"
      from_port        = "80"
      to_port          = "80"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = null
    }
  ]

  egress = [
    {
      description      = "Allow all"
      from_port        = "0"
      to_port          = "0"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = null
    }
  ]

  tags = {
    "Name" = "allow_ssh_http"
  }
}

resource "aws_security_group" "allow-mongodb" {
  name        = format("%s-allowmongodb", local.name)
  description = "Allow connections mongodb ports"
  vpc_id      = data.aws_vpc.vpc.id

  ingress = [
    {
      description      = "Allow mongodb"
      from_port        = "27017"
      to_port          = "27017"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = null
    }
  ]

  egress = [
    {
      description      = "Allow all"
      from_port        = "0"
      to_port          = "0"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = null
    }
  ]
  tags = {
    "Name" = "allow_mongodb"
  }
}

resource "aws_network_interface_sg_attachment" "app-sg" {
  count                = lookup(var.instance_count, var.env)
  security_group_id    = aws_security_group.allow-ssh.id
  network_interface_id = aws_instance.app-ec2[count.index].primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "mongodb-sg" {
  security_group_id    = aws_security_group.allow-mongodb.id
  network_interface_id = aws_instance.app-mongodb.primary_network_interface_id
}

resource "aws_route53_zone" "app-zone" {
  name  = format("%s.com.br", var.project)
  count = var.create_zone_dns == false ? 0 : 1

  vpc {
    vpc_id = data.aws_vpc.vpc.id
  }
}

resource "aws_route53_record" "mongodb" {
  count   = var.env == "prod" ? 1 : var.create_zone_dns == false ? 0 : 1
  zone_id = aws_route53_zone.app-zone[count.index].id
  name    = "mongodb.turma08.com.br"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.app-mongodb.private_ip]
}
