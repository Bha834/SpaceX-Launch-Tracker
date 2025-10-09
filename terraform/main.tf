provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "spacex-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.region}a"
}

resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id }

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.igw.id }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ssh_http" {
  name = "ssh-http"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 5000; to_port = 5000; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 9090; to_port = 9090; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] # prometheus
  }
  ingress {
    from_port = 3000; to_port = 3000; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] # grafana
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_key_pair" "deployer" {
  key_name = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "app" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.public.id
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ssh_http.id]
  tags = { Name = "spacex-app" }
}

resource "aws_instance" "jenkins" {
  ami           = var.ami
  instance_type = "t3.medium"
  subnet_id = aws_subnet.public.id
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ssh_http.id]
  tags = { Name = "spacex-jenkins" }
}

resource "aws_instance" "monitor" {
  ami           = var.ami
  instance_type = "t3.medium"
  subnet_id = aws_subnet.public.id
  key_name = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ssh_http.id]
  tags = { Name = "spacex-monitor" }
}

output "app_public_ip" { value = aws_instance.app.public_ip }
output "jenkins_public_ip" { value = aws_instance.jenkins.public_ip }
output "monitor_public_ip" { value = aws_instance.monitor.public_ip }
