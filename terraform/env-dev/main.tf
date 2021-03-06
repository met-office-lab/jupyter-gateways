resource "aws_route53_record" "dashboards" {
  zone_id = "${var.aws_dns_zone_id}"
  name = "${var.dashboards_dns}."
  type = "A"
  ttl = "60"
  records = ["${aws_instance.jupyter_gateways.public_ip}"]
}

resource "aws_route53_record" "api" {
  zone_id = "${var.aws_dns_zone_id}"
  name = "${var.api_dns}."
  type = "A"
  ttl = "60"
  records = ["${aws_instance.jupyter_gateways.public_ip}"]
}

resource "aws_security_group" "jupyter_gateways" {
  name = "${var.environment}_jupyter_gateways"
}

resource "aws_security_group_rule" "http_incoming" {
  type = "ingress"
  from_port = "80"
  to_port = "80"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.jupyter_gateways.id}"
}

resource "aws_instance" "jupyter_gateways" {
  # Amazon ECS optimised ami
  ami = "ami-9398d3e0"
  instance_type = "t2.micro"
  
  key_name = "gateway"
  security_groups = ["default", "${aws_security_group.jupyter_gateways.name}"]

  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = "${file("~/.ssh/gateway/id_rsa")}"
    bastion_host = "gateway.informaticslab.co.uk"
    bastion_user = "ec2-user"
    bastion_private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    source = "../../docker"
    destination = "~/jupyter_gateways"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.9.0/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo service docker start",
      "export API_DNS=${var.api_dns}",
      "export DASHBOARD_DNS=${var.dashboards_dns}",
      "cd ~/jupyter_gateways && sudo -E /usr/local/bin/docker-compose up -d"
    ]
  }
 
  tags {
    Name = "${var.environment}_jupyter_gateways"
    environoment = "dev"
  }
}
