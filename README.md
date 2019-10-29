# mongodb-terraform-deployment
An automated setup to deploy a MongoDB Cluster with a Replica Set (1 Primary, n Secondary nodes)

This project creates in AWS a VPC, Public/Private subnets, a Jumpbox server in the public subnet, and a MongoDB cluster in the private subnets

### Deployment Architecture
![Deployment Architecture](MongoDB-Replica-Set-Deployment-Architecture.png)

### Steps to Deploy
1. Clone this repository
2. cd into the repository
3. Edit the variables in the terraform.tfvars file
```hcl
  vpc_name = "mongo_vpc"
  replica_set_name = "mongoRs"
  num_secondary_nodes = 2
  mongo_username = "admin"
  mongo_password = "mongo4pass"
  mongo_database = "admin"
```
4. Set up the AWS CLI on your development machine and configure the ~/.aws/credentials file
```
  [default]
  aws_access_key_id = xxxxxxxxxxxxxxxxxx
  aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
5. Install [Terraform] on your development machine

[Terraform]: https://www.terraform.io/downloads.html

6. Use "terraform init" to initialize the modules

7. Use "terraform plan" to view the resources that would be created

8. Use "terraform apply" to deploy the cluster
