output "public_subnet_ids" {
  value = "${aws_subnet.public_subnets.*.id}"
}

output "private_subnet_ids" {
  value = "${aws_subnet.private_subnets.*.id}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "vpc_name" {
  value = "${var.vpc_name}"
}

output "vpc_cidr_block" {
  value = "${aws_vpc.main.cidr_block}"
}