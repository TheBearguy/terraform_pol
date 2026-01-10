terraform {
  # arguments
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.27.0"
    } 
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.57.0"
    }
  }
}