data "aws_ami" "amazon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-2018*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "userdata" {
  template = "${file("${path.module}/jumpbox_userdata.sh")}"
}

resource "aws_instance" "jumpbox" {

  ami                         = "${data.aws_ami.amazon_linux_ami.id}"
  instance_type               = "t2.nano"
  key_name                    = "${var.key_name}"
  subnet_id                   = "${var.subnet_id}"
  associate_public_ip_address = true
  user_data                   = "${data.template_file.userdata.rendered}"
  vpc_security_group_ids      = ["${aws_security_group.jumpbox_sg.id}"]
  root_block_device {
    volume_type = "standard"
  }

  tags = {
    Name = "Jumpbox"
  }

    provisioner "file" {
    source      = "~/.ssh/id_rsa"
    destination = "/home/ec2-user/id_rsa"

    connection {
      type         = "ssh"
      user         = "ec2-user"
      host         = "${self.public_ip}"
      agent        = false
      private_key  = "${file("~/.ssh/id_rsa")}"
    }
  }

}

resource "aws_security_group" "jumpbox_sg" {
  name   = "jumpbox_sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Jumpbox_Security_Group"
  }
}