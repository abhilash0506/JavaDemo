terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.29.1"
    }
  }
}

provider "aws" {
  # Configuration options
    region = "ap-south-1"

}