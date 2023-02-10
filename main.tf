# changes made = 'richardgurney' -> 'groupone'

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


provider "aws" {
  region     = var.AWS_DEFAULT_REGION
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}


# Create our VPC
resource "aws_vpc" "groupone-application-deployment" {
  cidr_block = "10.15.0.0/16"

  tags = {
    Name = "groupone-application-deployment-vpc"
  }
}

resource "aws_internet_gateway" "groupone-ig" {
  vpc_id = "${aws_vpc.groupone-application-deployment.id}"

  tags = {
    Name = "groupone-ig"
  }
}

resource "aws_route_table" "groupone-rt" {
  vpc_id = "${aws_vpc.groupone-application-deployment.id}"
  
  route {
    cidr_block = "0.0.0.0/0" # Anywhere - access the internet from inside the network
    gateway_id = "${aws_internet_gateway.groupone-ig.id}"
  }
}


data "aws_ami" "db-ami" {

most_recent = true 

filter {
    name   = "name"
    values = ["augusta-image-group1-DATABASE*"]
  }

filter {
  name = "state"
  values = ["available"]
}

filter {
    name = "root-device-type"
    values = ["ebs"]
}

}

module "db-tier" {
  name           = "groupone-database"
  region         = var.AWS_DEFAULT_REGION
  source         = "./modules/db-tier"
  vpc_id         = "${aws_vpc.groupone-application-deployment.id}"
  route_table_id = "${aws_vpc.groupone-application-deployment.main_route_table_id}"
  cidr_block              = "10.15.1.0/24" # TODO ---> Make sure the cidr block is the same across the configuration files 
  user_data               = templatefile("./scripts/database_user_data.sh", {})
  ami_id                  = "${data.aws_ami.db-ami.id}" # TODO--> Will need to insert the database ami once packer is built // *ADDED*
  map_public_ip_on_launch = false

  ingress = [
    {
      from_port = 27017
      to_port = 27017
      protocol = "tcp"
      cidr_blocks = "${module.application-tier.subnet_cidr_block}"
    }
  ]
}


data "aws_ami" "app-ami" {

most_recent = true 

filter {
    name   = "name"
    values = ["augusta-image-group1-APP*"]
  }

filter {
  name = "state"
  values = ["available"]
}

filter {
    name = "root-device-type"
    values = ["ebs"]
}

}

module "application-tier" {
  name                    = "groupone-app"
  region                  = var.AWS_DEFAULT_REGION
  source                  = "./modules/application-tier"
  vpc_id                  = "${aws_vpc.groupone-application-deployment.id}"
  route_table_id          = "${aws_route_table.groupone-rt.id}"
  cidr_block              = "10.15.0.0/24" # TODO---> Make sure the cidr block is the same across the configuration files
  user_data               = templatefile("./scripts/app_user_data.sh", { mongodb_ip=module.db-tier.private_ip })
  ami_id                  = "${data.aws_ami.app-ami.id}" # TODO---> Will need to insert the Application ami once packer is built // *ADDED* 
  map_public_ip_on_launch = true

  ingress = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22 
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0" # TODO: <--YOU WILL NEED TO CHANGE TO YOUR IP ADDRESS FOR SECURITY!
    }
  ]
}