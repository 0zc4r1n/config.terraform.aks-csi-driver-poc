# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.app_name}-${terraform.workspace}-rg"
  location = var.location

  tags = {
    environment = terraform.workspace
    app         = var.app_name
  }
}

# Create a virtual network and subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.app_name}-${terraform.workspace}-vnet"
  address_space       = ["11.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = terraform.workspace
    app         = var.app_name
  }
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["11.0.0.0/24"]
}

# Data from Azure Key Vault instance
data "azurerm_key_vault" "kv" {
  name                = "ans-keyvault-dev"
  resource_group_name = "Resource_Group_ANS_QA-UAT"
}

# Create an AKS cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.app_name}-${terraform.workspace}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.app_name}-${terraform.workspace}-aks"

  node_resource_group = "${var.app_name}-${terraform.workspace}-aks-nodes"

  # To prevent CIDR collition with the 10.0.0.0/16 Vnet
  network_profile {
    network_plugin = "kubenet"
    dns_service_ip = "192.168.1.1"
    service_cidr   = "192.168.0.0/16"
    pod_cidr       = "172.16.0.0/22"
  }

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # Enable workload identity
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = {
    environment = terraform.workspace
    app         = var.app_name
  }
}

resource "azurerm_user_assigned_identity" "wif_identity" {
  location            = azurerm_resource_group.rg.location
  name                = "workload-identity-${terraform.workspace}"
  resource_group_name = azurerm_resource_group.rg.name
}

data "azurerm_client_config" "current" {}

# Create a azure key vault instance
resource "azurerm_key_vault" "kv" {
  name                       = "${var.app_name}${terraform.workspace}-kv"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true

  tags = {
    environment = terraform.workspace
    app         = var.app_name
  }
}

# Assign access policies to current user
resource "azurerm_key_vault_access_policy" "aks-kv-current-access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions         = ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "Release", "Rotate", "GetRotationPolicy", "SetRotationPolicy"]
  secret_permissions      = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
  certificate_permissions = ["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"]
  storage_permissions     = ["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"]

  depends_on = [
    azurerm_key_vault.kv
  ]
}

# Assign access policies to AKS cluster service principal
resource "azurerm_key_vault_access_policy" "aks-kv-sp-access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.wif_identity.principal_id

  key_permissions         = ["Get"]
  secret_permissions      = ["Get"]
  certificate_permissions = ["Get"]

  depends_on = [
    azurerm_key_vault.kv
  ]
}

resource "azurerm_federated_identity_credential" "federated_identity_credential" {
  name                = "federated-identity-credential-${terraform.workspace}"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.wif_identity.id
  subject             = "system:serviceaccount:wif:wif-sa"
}