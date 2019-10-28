data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "nat_instance_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "${var.vpc_name}_IG"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = 3
  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block              = "192.168.${count.index + 1}.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}_Public_Subnet_${count.index + 1}"
    Type = "Public"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = 3
  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index + 3]}"
  cidr_block        = "192.168.${count.index + 4}.0/24"

  tags = {
    Name = "${var.vpc_name}_Private_Subnet_${count.index + 1}"
    Type = "Private"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "${var.vpc_name}_Public_Route_Table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = 3
  subnet_id      = "${element(aws_subnet.public_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "${var.vpc_name}_Private_Route_Table"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = "${aws_route_table.private_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  instance_id            = "${aws_instance.nat_instance.id}"
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = 3
  subnet_id      = "${element(aws_subnet.private_subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}

resource "aws_instance" "nat_instance" {

  ami                         = "${data.aws_ami.nat_instance_ami.id}"
  instance_type               = "t2.micro"
  source_dest_check           = false
  associate_public_ip_address = true
  key_name                    = "${var.key_name}"
  subnet_id                   = "${element(aws_subnet.public_subnets.*.id, 0)}"
  vpc_security_group_ids      = ["${aws_security_group.nat_sg.id}"]

  tags = {
    Name = "${var.vpc_name}_NAT_Instance"
  }

}

resource "aws_security_group" "nat_sg" {
  name   = "nat_instance_security_group"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${aws_subnet.private_subnets.*.cidr_block}"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${aws_subnet.private_subnets.*.cidr_block}"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = "${aws_subnet.private_subnets.*.cidr_block}"
  }

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
    Name = "NAT_Instance_Security_Group"
  }
}
