terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.18"
    }
  }

  required_version = ">= 1.2.2"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "icecat_build" {
  ami           = "ami-08b7bda26f4071b80"
  instance_type = "m5.4xlarge"
  key_name      = "icecat-build-aws"

  root_block_device {
    volume_size = "40"
  }

  tags = {
    Name = "icecat-build"
  }
}

output "instance_ip" {
  value = aws_instance.icecat_build.public_ip
}
