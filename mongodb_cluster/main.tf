data "aws_ami" "ubuntu_18_image" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_region" "current" {}


data "template_file" "userdata" {
  template = "${file("${path.module}/mongo_userdata.sh")}"
  vars = {
    replica_set_name = "${var.replica_set_name}"
    mongo_password = "${var.mongo_password}"
    mongo_username = "${var.mongo_username}"
    mongo_database = "${var.mongo_database}"
    aws_region = "${data.aws_region.current.name}"
  }
}

resource "aws_instance" "mongo_secondary" {
  count                  = "${var.num_secondary_nodes}"
  ami                    = "${data.aws_ami.ubuntu_18_image.id}"
  instance_type          = "${var.secondary_node_type}"
  key_name               = "${var.key_name}"
  subnet_id              = "${var.private_subnet_ids[count.index % length(var.private_subnet_ids)]}"
  user_data              = "${data.template_file.userdata.rendered}"
  vpc_security_group_ids = ["${aws_security_group.mongo_sg.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.mongo-instance-profile.name}"
  root_block_device {
    volume_type = "standard"
  }

  tags = {
    Name = "Mongo-Secondary_${count.index + 1}"
    Type = "secondary"
  }

  provisioner "file" {
    source      = "${path.module}/populate_hosts_file.py"
    destination = "/home/ubuntu/populate_hosts_file.py"

    connection {
      type         = "ssh"
      user         = "ubuntu"
      host         = "${self.private_ip}"
      agent        = false
      private_key  = "${file("~/.ssh/id_rsa")}"
      bastion_host = "${var.jumpbox_public_ip}"
      bastion_user = "ec2-user"
    }
  }

  provisioner "file" {
    source      = "${path.module}/parse_instance_tags.py"
    destination = "/home/ubuntu/parse_instance_tags.py"

    connection {
      type         = "ssh"
      user         = "ubuntu"
      host         = "${self.private_ip}"
      agent        = false
      private_key  = "${file("~/.ssh/id_rsa")}"
      bastion_host = "${var.jumpbox_public_ip}"
      bastion_user = "ec2-user"
    }
  }

  provisioner "file" {
    source      = "${path.module}/keyFile"
    destination = "/home/ubuntu/keyFile"

    connection {
      type         = "ssh"
      user         = "ubuntu"
      host         = "${self.private_ip}"
      agent        = false
      private_key  = "${file("~/.ssh/id_rsa")}"
      bastion_host = "${var.jumpbox_public_ip}"
      bastion_user = "ec2-user"
    }
  }

}

resource "aws_instance" "mongo_primary" {
  ami                    = "${data.aws_ami.ubuntu_18_image.id}"
  instance_type          =  "${var.primary_node_type}"
  key_name               = "${var.key_name}"
  subnet_id              = "${var.private_subnet_ids[0]}"
  user_data              = "${data.template_file.userdata.rendered}"
  vpc_security_group_ids = ["${aws_security_group.mongo_sg.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.mongo-instance-profile.name}"
  root_block_device {
    volume_type = "standard"
  }

  tags = {
    Name = "Mongo-Primary"
    Type = "primary"
  }

  provisioner "file" {
    source      = "${path.module}/populate_hosts_file.py"
    destination = "/home/ubuntu/populate_hosts_file.py"

    connection {
      type         = "ssh"
      user         = "ubuntu"
      host         = "${self.private_ip}"
      agent        = false
      private_key  = "${file("~/.ssh/id_rsa")}"
      bastion_host = "${var.jumpbox_public_ip}"
      bastion_user = "ec2-user"
    }
  }

  provisioner "file" {
    source      = "${path.module}/parse_instance_tags.py"
    destination = "/home/ubuntu/parse_instance_tags.py"

    connection {
      type         = "ssh"
      user         = "ubuntu"
      host         = "${self.private_ip}"
      agent        = false
      private_key  = "${file("~/.ssh/id_rsa")}"
      bastion_host = "${var.jumpbox_public_ip}"
      bastion_user = "ec2-user"
    }
  }

    provisioner "file" {
    source      = "${path.module}/keyFile"
    destination = "/home/ubuntu/keyFile"

    connection {
      type         = "ssh"
      user         = "ubuntu"
      host         = "${self.private_ip}"
      agent        = false
      private_key  = "${file("~/.ssh/id_rsa")}"
      bastion_host = "${var.jumpbox_public_ip}"
      bastion_user = "ec2-user"
    }
  }

}

resource "aws_security_group" "mongo_sg" {
  name   = "mongo_sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
  from_port   = -1
  to_port     = -1
  protocol = "icmp"
  cidr_blocks        = ["${var.vpc_cidr_block}"]
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Mongo_Security_Group"
  }
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mongo-role" {
  name               = "mongo_role"
  path               = "/system/"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
}

resource "aws_iam_instance_profile" "mongo-instance-profile" {
  name = "mongo-instance-profile"
  role = "${aws_iam_role.mongo-role.name}"
}

resource "aws_iam_role_policy" "ec2-describe-instance-policy" {
  name = "ec2-describe-instance-policy"
  role = "${aws_iam_role.mongo-role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeTags"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}