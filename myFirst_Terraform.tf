
# This is my very first Terraform script. It is intentionally meant to be basic and is not meant to be pretty or elegant at 
# this point. The objective of this first script is simply to get it to work as expected. This was achieved successfully.  
# This script is the result of self-initiated learning for a few hours over a couple of days.
#__


provider "aws" {
  access_key = "XXXXXXXXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  profile = "default"
  region  = "us-west-1"
}

resource "aws_s3_bucket" "prod_tf_course" {
  bucket = "tf-course-20201016jt"
  acl    = "private"
}

resource "aws_default_vpc" "default" {}

# Adding a security group resource called prod_web



# These aws_default_subnets are needed for the ELBs near the end of this code
resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-west-1a"
    tags =  {
      "Terraform" : "true"
    }
}


resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-west-1b"
    tags =  {
      "Terraform" : "true"
    }
}




resource "aws_security_group" "prod_web"{
  name        = "prod_web"
  description = "Allow standard http and https ports inbound and everything outbound"

# Defining an ingress rule for inbound traffic
  ingress {
    from_port  = 80
    to_port    = 80
    protocol   = "tcp"
#   For learning purposes allow all IPs for now
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port  = 443 
    to_port    = 443 
    protocol   = "tcp"
#   For learning purposes allow all IPs for now
    cidr_blocks = ["0.0.0.0/0"]
  } 
    egress {
#     allowing all ports out
      from_port = 0
      to_port   = 0
#     allowing all protocols out
      protocol  = "-1"
#     allowing traffic out to any IP address
      cidr_blocks = ["0.0.0.0/0"]
    }
    
    tags =  {
      "Terraform" : "true"
    }

}


# Setting up an NGINIX Open Source Web Server Certified by Bitnami in the NCal region 
   resource "aws_instance" "prod_web" {
# Adding in the ability he change the instance count
     count  = 2 
     
     ami           = "ami-06d6181142644523b"
     instance_type = "t3a.small"

     vpc_security_group_ids = [
       aws_security_group.prod_web.id
     ]

     tags = {
      "Terraform" : "true"
     } 

 }

# This decouples the creation of the elastic IP from its assignment, for scalability purposes 
      resource "aws_eip_association" "prod_web" {
        instance_id = aws_instance.prod_web.0.id
        allocation_id = aws_eip.prod_web.id
      }


     resource "aws_eip" "prod_web" {
       tags = {
     "Terraform" : "true"
   }
}


resource "aws_elb" "prod_web" {
# In the name below you can only use alpha-numeric characters of a dash so if we want the name to sort of match we use the below.

             name = "prod-web" 
        instances = aws_instance.prod_web.*.id 

# After the instances we need the subnets that were defined earlier. See top of the code.

        subnets   = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]

# So our instances and our ELB  can talk to each other and talk to the world we need to add the below security group. We will
# only add one security group.  In Terraform security groups expect a list or and array, hence the brackets.

  security_groups = [aws_security_group.prod_web.id]

            listener {
              instance_port     = 80
              instance_protocol = "http"
              lb_port           = 80 
              lb_protocol       = "http" 

           }
       tags = {
         "Terraform" : "true"
   }

}

