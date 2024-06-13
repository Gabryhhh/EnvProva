
variable "aws_region" {
  description = "The AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "subnet_ids" {
  description = "List of Subnet IDs"
  type        = list(string)
}

variable "key_name" {
  description = "Name of an existing EC2 KeyPair to enable SSH access to the ECS instances."
  type        = string
}

variable "vpc_id" {
  description = "Select a VPC that allows instances to access the Internet."
  type        = string
}

variable "desired_capacity" {
  description = "Number of instances to launch in your ECS cluster."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances that can be launched in your ECS cluster."
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium", "t2.large", "m3.medium", "m3.large", "m3.xlarge", "m3.2xlarge", "m4.large", "m4.xlarge", "m4.2xlarge", "m4.4xlarge", "m4.10xlarge", "c4.large", "c4.xlarge", "c4.2xlarge", "c4.4xlarge", "c4.8xlarge", "c3.large", "c3.xlarge", "c3.2xlarge", "c3.4xlarge", "c3.8xlarge", "r3.large", "r3.xlarge", "r3.2xlarge", "r3.4xlarge", "r3.8xlarge", "i2.xlarge", "i2.2xlarge", "i2.4xlarge", "i2.8xlarge"], var.instance_type)
    error_message = "Please choose a valid instance type."
  }
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "ecs-cluster"
}
