provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

module "vpc_281" {
  source   = "./vpc"
  key_name = "${module.key_pair_281.key_name}"
  vpc_name = "${var.vpc_name}"
}

module "key_pair_281" {
  source     = "./key_pair"
  key_name   = "cmpe281-us-east-1"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
  }

module "jumpbox" {
  source    = "./jumpbox"
  key_name  = "${module.key_pair_281.key_name}"
  vpc_id    = "${module.vpc_281.vpc_id}"
  subnet_id = "${module.vpc_281.public_subnet_ids[1]}"
}

module "mongodb_cluster" {
  source             = "./mongodb_cluster"
  key_name           = "${module.key_pair_281.key_name}"
  vpc_id             = "${module.vpc_281.vpc_id}"
  private_subnet_ids = "${module.vpc_281.private_subnet_ids}"
  jumpbox_public_ip  = "${module.jumpbox.jumpbox_public_ip}"
  replica_set_name = "${var.replica_set_name}"
}