provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

module "vpc" {
  source   = "./vpc"
  key_name = "${module.key_pair.key_name}"
  vpc_name = "${var.vpc_name}"
}

module "key_pair" {
  source     = "./key_pair"
  key_name   = "mongo-key-pair"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
  }

module "jumpbox" {
  source    = "./jumpbox"
  key_name  = "${module.key_pair.key_name}"
  vpc_id    = "${module.vpc.vpc_id}"
  subnet_id = "${module.vpc.public_subnet_ids[1]}"
}

module "mongodb_cluster" {
  source             = "./mongodb_cluster"
  key_name           = "${module.key_pair.key_name}"
  vpc_id             = "${module.vpc.vpc_id}"
  private_subnet_ids = "${module.vpc.private_subnet_ids}"
  jumpbox_public_ip  = "${module.jumpbox.jumpbox_public_ip}"
  replica_set_name = "${var.replica_set_name}"
  num_secondary_nodes = "${var.num_secondary_nodes}"
  mongo_username = "${var.mongo_username}"
  mongo_database = "${var.mongo_database}"
  mongo_password = "${var.mongo_password}"
}