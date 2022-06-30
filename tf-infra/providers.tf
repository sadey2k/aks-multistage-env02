terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.0"
    }
  }
}

provider "azurerm" {
  features {}
}


###################################################
## TF Backend ##
###################################################

terraform {
  backend "azurerm" {
    resource_group_name  = "sadey2k-backendRG"
    storage_account_name = "sadey2ksa"
    container_name       = "tfstate"
    key                  = "terraform-tfstate-QA"
  }
} 