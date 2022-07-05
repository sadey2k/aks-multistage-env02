#################################################
## Resource group  ##
#################################################
resource "azurerm_resource_group" "pipeline-aks-rg" {
  name      = "${var.aks_rg_name}-${var.tags}"
  location  = var.location
}

#################################################
## Create log analytics workspace ##
#################################################
resource "azurerm_log_analytics_workspace" "sadey2kworkspace" {
    # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
    name                = "${var.log_analytics_workspace_name}-${var.tags}"
    location            = var.location
    resource_group_name = azurerm_resource_group.pipeline-aks-rg.name
    sku                 = var.log_analytics_workspace_sku
    depends_on = [
      azurerm_resource_group.pipeline-aks-rg
    ]
}

#################################################
## Key vault values  ##
#################################################
data "azurerm_key_vault" "azure_vault" {
  name                = var.keyvault_name
  resource_group_name = var.keyvault_rg
}

data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = var.sshkvsecret
  key_vault_id = data.azurerm_key_vault.azure_vault.id
}

data "azurerm_key_vault_secret" "spn_id" {
  name         = var.clientidkv
  key_vault_id = data.azurerm_key_vault.azure_vault.id
}
data "azurerm_key_vault_secret" "spn_secret" {
  name         = var.spnkvsecret
  key_vault_id = data.azurerm_key_vault.azure_vault.id
}

data "azurerm_key_vault_secret" "sa_access_key" {
  name = var.access_key
  key_vault_id = data.azurerm_key_vault.azure_vault.id
}

#################################################
## Create cluster  ##
#################################################
resource "azurerm_kubernetes_cluster" "k8s" {
    name                = "${var.aks_cluster_name}-${var.tags}"
    location            = var.location
    resource_group_name = "${var.aks_rg_name}-${var.tags}"
    dns_prefix          = "${var.dns_prefix}-${var.tags}"

    linux_profile {
        admin_username = "ubuntu"

        ssh_key {
            key_data = data.azurerm_key_vault_secret.ssh_public_key.value
        }
    }

    default_node_pool {
        name            = "agentpool"
        node_count      = var.agent_count
        vm_size         = "Standard_D2_v2"
    }

    service_principal {
        client_id     = data.azurerm_key_vault_secret.spn_id.value
        client_secret = data.azurerm_key_vault_secret.spn_secret.value
    }

    # addon_profile {
    #     oms_agent {
    #     enabled                    = true
    #     log_analytics_workspace_id = azurerm_log_analytics_workspace.sadey2kworkspace.id
    #     }
    # }

    network_profile {
        load_balancer_sku = "standard"
        network_plugin = "kubenet"
    }

    tags = {
        Environment = var.tags
    }
}
