# Create a variable for the resource group name
variable "app_name" {
  type    = string
  default = "ans-aks-csi-driver"
}

# Create a variable for the location
variable "location" {
  type    = string
  default = "eastus2"
}