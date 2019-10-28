output "jumpbox_public_ip" {
  value = "${aws_instance.jumpbox.public_ip}"
}
