terraform {
  backend "azurerm" {
    storage_account_name = "tfstatestrg0"
    container_name       = "tfstatecontainer"
    key                  = "terraform.tfstate"
    access_key           = "L4y+MyUQnilHKr5UAWfnnJDFkk7x/qdYzftIcXu7s1Q9p/HbZNTL6obfLPXV1YEGQAoUyX2mrQAc+AStMMaiUw=="
  }
}